<script>
  // remember, <script> tags are where the logic lives
  import world from "$data/world-110m.json";
  import * as topojson from "topojson-client";
  import { geoOrthographic, geoPath } from "d3-geo";
  import Glow from "$components/Glow.svelte";
  import data from "$data/nci_final_data.json";
 // import data from "$data/data.json";
  import { timer } from "d3-timer";
  import Tooltip from "$components/Tooltip.svelte";
  import { draw } from "svelte/transition";

  let countries = topojson.feature(world, world.objects.countries).features;
  let borders = topojson.mesh(
    world,
    world.objects.countries,
    (a, b) => a !== b,
  );
  let width = 400;
  $: height = width;

  // re-structure the countries array to include the population data
  countries.forEach((country) => {
    const metadata = data?.find((d) => d.id === country.id);
    // console.log(metadata);
    if (metadata) { 
      country.score = metadata.score;
     // country.population = metadata.population;
      country.country = metadata.country;
    }
  });

  import { scaleLinear } from "d3-scale";
  import { max, min, sort } from "d3-array";
  import { spring } from "svelte/motion";
  import Legend from "$components/Legend.svelte";

  const lightGrey = "#3c3c3c"; // Define light grey color for countries with no score

  // ORIGINAL
//   const colorScale = scaleLinear()
//    // .domain([0, max(data, (d) => d.score)]) // original
//    .domain([
//   min(data.filter(d => !isNaN(Number(d.score))), d => Number(d.score)), 
//   max(data.filter(d => !isNaN(Number(d.score))), d => Number(d.score))
// ])
//     .range(["#963826", "#0dcc6c"]);

const colorScale = scaleLinear()
  .domain([
    min(data.filter(d => !isNaN(Number(d.score))), d => Number(d.score)),  // Dark Red (Low)
    (min(data.filter(d => !isNaN(Number(d.score))), d => Number(d.score)) +
     max(data.filter(d => !isNaN(Number(d.score))), d => Number(d.score))) / 2, // Tan (Middle)
    max(data.filter(d => !isNaN(Number(d.score))), d => Number(d.score))  // Bright Green (High)
  ])
  .range(["#8e0152", "#E5C07B", "#276419"]);  // purple → tan → dark green 



  // what projection should be applied to the raw coordinates
  $: projection = geoOrthographic()
    .scale(width / 2)
    .rotate([$xRotation, $yRotation, 0])
    .translate([width / 2, height / 2]);

  // creating a new path function that uses a series of coordinates to create
  // an svg shape
  $: path = geoPath(projection);

  const color_globe_borders = "#1c1c1c";

  let xRotation = spring(0, { stiffness: 0.08, damping: 0.4 });
  let yRotation = spring(0, { stiffness: 0.1, damping: 0.7 });

  let degreesPerFrameX = 0.2;
  let degreesPerFrameY = 0;

  // AUTO-ROTATE THE GLOBE
  const t = timer((elapsed) => {
    if (dragging || tooltipData) return;
    $xRotation += degreesPerFrameX; // rotation = rotation + degreesPerFrame
    $yRotation += degreesPerFrameY; // rotation = rotation + degreesPerFrame
  }, 0); // the delay. 0 means start the rotation immediately

  // USER-CONTROLLED ROTATION
  let globe;
  $: console.log(globe);

  import { onMount } from "svelte";
  import { drag } from "d3-drag";
  import { select } from "d3-selection";

  const DRAG_SENSITIVITY = 1;
  let dragging = false;

  onMount(() => {
    // console.log("page has loaded");
    // d3 drag, brush, zoom, etc handlers must be called on a selection
    // rather than a native svg element
    const element = select(globe);
    element.call(
      drag()
        .on("drag", (event) => {
          $xRotation = $xRotation + event.dx * DRAG_SENSITIVITY;
          $yRotation = $yRotation - event.dy * DRAG_SENSITIVITY;
          dragging = true;
        })
        .on("end", () => {
          dragging = false;
        }),
    );
  });

  let tooltipData;
  import { geoCentroid } from "d3-geo";

  $: {
    if (tooltipData) {
      const center = geoCentroid(tooltipData);
      $xRotation = -center[0];
      $yRotation = -center[1];
    }
  }
</script>

<!-- THE SVG ELEMENTS -->
<div class="chart-container" bind:clientWidth={width}>
  <h1 class="title">The Nature Conservation Index</h1>
  <h2>NCI by Country, 2024</h2>
  <svg {width} {height} bind:this={globe} class:dragging>
    <!-- Glow styling -->
    <Glow />
    <!-- The Globe -->
    <!-- svelte-ignore a11y-click-events-have-key-events -->
    <!-- svelte-ignore a11y-no-noninteractive-tabindex -->
    <circle
      cx={width / 2}
      cy={height / 2}
      r={width / 2}
      fill={color_globe_borders}
      filter="url(#glow)"
      on:click={() => {
        tooltipData = null;
      }}
      on:focus={() => {
        tooltipData = null;
      }}
      tabindex="0"
    />
    <!-- COUNTRIES -->
    {#each countries as country}
      <!-- svelte-ignore a11y-click-events-have-key-events -->
      <!-- svelte-ignore a11y-no-noninteractive-tabindex -->
       <!-- ORIGINAL: fill={colorScale(country?.score || 0)}  -->
      <path
        d={path(country)}
        fill={isNaN(Number(country.score)) ? lightGrey : colorScale(Number(country.score))}
        stroke="none"
        on:click={() => {
          tooltipData = country;
        }}
        on:focus={() => {
          tooltipData = country;
        }}
        tabindex="0"
      />
    {/each}

    <!-- All BORDERS -->
    <path d={path(borders)} fill="none" stroke={color_globe_borders} />
    <!-- Selected Country's BORDER -->
    {#if tooltipData}
      {#key tooltipData.country}
        <path
          d={path(tooltipData)}
          fill="none"
          stroke="white"
          stroke-width="2"
          in:draw
        />
      {/key}
    {/if}
  </svg>
  <Tooltip data={tooltipData} />
  <Legend {colorScale} data={tooltipData} />
</div>

<!-- CSS STYLING -->
<style>
  @import url("https://fonts.googleapis.com/css2?family=Roboto+Mono:wght@400;700&display=swap");

  body {
    font-family: "Roboto Mono", monospace;
  }

  .chart-container {
    max-width: 468px;
    margin: 0 auto;
  }

  :global(body) {
    background:
      linear-gradient(rgba(0, 0, 0, 0.3), rgba(0, 0, 0, 0.3)),
      url("media/space-bg.avif") center;
    background-size: cover;
  }

  svg {
    overflow: visible;
    margin-bottom: 2rem;
  }

  .dragging {
    cursor: grabbing;
  }

  path {
    cursor: pointer;
  }

  /* typically, removing focus styling is a bad idea. However, we've already manually added the 
  white outline to the focused country.  */
  path:focus {
    outline: none;
  }

  circle:focus {
    outline: none;
  }

  h1,
  h2 {
    color: #d8e5ed;
    text-align: center;
    font-family: "Roboto Mono", monospace;
  }

  h1 {
    font-size: 1.75rem;
    font-weight: 800;
    margin-bottom: 0.75rem;
  }

  h2 {
    font-size: 1rem;
    font-weight: 200;
    margin-bottom: 2rem;
  }
</style>
