# Waste per person by income

Katukiza et al. (2026) weighed the domestic solid waste of 103
households in three Kampala parishes over one week. The chart below
shows one dot per household: the kg of waste each person generates per
day, grouped by the income level of the parish, with the median of each
group. Waste per person rises with income, from a median of 0.32 kg in
the low income parish to 0.93 kg in the high income parish. Hover over a
dot to see that household.

``` js
households = transpose(households_data)
medians = transpose(medians_data)

// chart-1 and chart-2 from openwashdata/brand
palette = ["#8a3a8a", "#b04208"]

Plot.plot({
  width: Math.max(280, width),
  height: 360,
  marginLeft: 10,
  marginRight: 10,
  marginTop: 6,
  marginBottom: 40,
  style: {fontSize: 13, background: "transparent"},
  ariaLabel: "Dot plot of waste per person per day for 103 households in Kampala, one row per income level",
  ariaDescription: "The median rises from 0.32 kg in the low income parish to 0.57 in the middle income parish and 0.93 in the high income parish. Households spread from near zero to about 1.9 kg.",
  fy: {domain: label_order, axis: null, padding: 0.25},
  x: {label: "kg of waste per person per day", labelAnchor: "center", domain: [0, 2], grid: true, ticks: 5},
  marks: [
    Plot.dot(households, Plot.dodgeY("middle", {
      fy: "label",
      x: "per_capita",
      r: 3.6,
      fill: palette[0],
      fillOpacity: 0.75,
      stroke: "#ffffff",
      strokeWidth: 0.6,
      tip: true,
      title: (d) => `${d.household}\n${d.per_capita} kg per person per day\n${d.occupants} people, ${d.per_day} kg per day\n${d.label} (${d.parish})`
    })),
    Plot.ruleX(medians, {fy: "label", x: "median", stroke: palette[1], strokeWidth: 2}),
    Plot.text(medians, {
      fy: "label",
      x: "median",
      text: (d) => `median ${d.median} kg`,
      frameAnchor: "bottom",
      textAnchor: "start",
      dx: 5,
      dy: -1,
      fill: palette[1],
      fontWeight: 600
    }),
    // row titles last, with a halo so the median line does not cut through them
    Plot.text(medians, {
      fy: "label",
      text: (d) => `${d.label} (${d.parish}), ${d.n} households`,
      frameAnchor: "top-left",
      dx: 2,
      dy: -2,
      fontWeight: 700,
      fill: "#1e1e1e",
      stroke: "#ffffff",
      strokeWidth: 5
    })
  ]
})
```

The chart is adapted from the dataset of the month on
[openwashdata.org](https://openwashdata.org). For the full analysis, see
the paper:

> Katukiza, A. Y., Niwagaba, C. B., Feni, I., Namagembe, S., Semiyaga,
> S., Batte, A., & Manga, M. (2026). Quantity and composition of
> domestic solid waste in Kampala City as influenced by socioeconomic
> factors. *Frontiers in Environmental Science*, 14.
> <https://doi.org/10.3389/fenvs.2026.1889921>
