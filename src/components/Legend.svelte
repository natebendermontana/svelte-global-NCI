<script>
    export let data;
    export let colorScale;
    import { fade } from "svelte/transition";
    import { format } from "d3-format";

    // const suffixFormat = (d) => format(".2s")(d).replace("G", "B");
    const minValue = colorScale.domain()[0];
    const midValue = (minValue + colorScale.domain()[2]) / 2; // Midpoint for tan color
    const maxValue = colorScale.domain()[2];

    // Get the three color stops
    const minColor = colorScale.range()[0]; // Dark Red
    const midColor = colorScale.range()[1]; // Tan
    const maxColor = colorScale.range()[2]; // Bright Green

    //  $: percentofMax = (data?.score / maxValue) * 100;
    $: percentofMax = isNaN(Number(data?.score))
        ? null
        : ((Number(data?.score) - minValue) / (maxValue - minValue)) * 100;

        $: console.log({percentofMax})
</script>

<div class="legend">
    <span class="label">{minValue}</span>
    <div
        class="bar"
        style:background="linear-gradient(to right, 
            {minColor} 0%, 
            {midColor} 50%, 
            {maxColor} 100%)"
            >
        {#if percentofMax}
            <span
                class="line"
                style:left={percentofMax + "%"}
                transition:fade
            />
        {/if}
    </div>
    <span class="label">{maxValue}</span>
</div>

<style>
    .legend {
        display: flex;
        flex-direction: row;
        gap: 6px;
    }

    .bar {
        height: 15px;
        width: 100%;
        position: relative;
    }

    .label {
        color: white;
        font-size: 0.85rem;
        user-select: none;
    }

    .line {
        position: absolute;
        top: 0px;
        height: 15px;
        width: 2px;
        background: white;
        transition: left 500ms cubic-bezier(1, 0, 0, 1);
    }
</style>
