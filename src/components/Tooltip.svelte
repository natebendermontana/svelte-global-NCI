<script>
    export let data;
import { format } from "d3-format";
import { fade } from "svelte/transition";
const suffixFormat = (d) => format(".2s")(d).replace("G", "B");


</script>

{#if data?.country}
{#key data.country}
<div in:fade out:fade>
    <h2>{data.country}</h2>
    <h3>Score of {suffixFormat(data.score)}</h3>
</div>
{/key}
{/if}

<style>
    div {
        position: absolute;
        bottom: 30px; 
        right: 0px;
        text-align: right;
    }

    h2 {
        font-size: 1.5rem;
        font-weight: 700;
        color: white;
        margin-bottom: .25rem;
    }

    h3 {
        font-size: 1.15rem;
        font-weight: 200;
        color: rgba(255,255,255, .7);
    }
</style>