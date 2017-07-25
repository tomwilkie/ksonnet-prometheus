{
  dashboard(title):: {
    annotations: {
      list: [],
    },
    hideControls: false,
    id: 1,
    links: [],
    rows: [],
    schemaVersion: 14,
    style: "dark",
    tags: [],
    editable: true,
    gnetId: null,
    graphTooltip: 0,
    templating: {
      list: [],
    },
    time: {
      from: "now-1h",
      to: "now",
    },
    refresh: "10s",
    timepicker: {
      refresh_intervals: [
        "5s",
        "10s",
        "30s",
        "1m",
        "5m",
        "15m",
        "30m",
        "1h",
        "2h",
        "1d",
      ],
      time_options: [
        "5m",
        "15m",
        "1h",
        "6h",
        "12h",
        "24h",
        "2d",
        "7d",
        "30d",
      ],
    },
    timezone: "utc",
    title: title,
    version: 0,
  },

  template(name, metric_name, label_name):: {
    templating+: {
      list+: [
        {
          allValue: null,
          current: {
            text: "prod",
            value: "prod",
          },
          datasource: "Prometheus",
          hide: 0,
          includeAll: false,
          label: name,
          multi: false,
          name: name,
          options: [],
          query: "label_values(%s, %s)" % [metric_name, label_name],
          refresh: 1,
          regex: "",
          sort: 2,
          tagValuesQuery: "",
          tags: [],
          tagsQuery: "",
          type: "query",
          useTags: false,
        },
      ],
    },
  },

  row(title):: {
    collapse: false,
    height: "250px",
    repeat: null,
    repeatIteration: null,
    repeatRowId: null,
    showTitle: true,
    title: title,
    titleSize: "h6",
  },

  addRow(row):: {
    rows+: [row],
  },

  panel(title, id):: {
    aliasColors: {},
    bars: false,
    dashLength: 10,
    dashes: false,
    datasource: "Prometheus",
    fill: 1,
    id: id,
    legend: {
      avg: false,
      current: false,
      max: false,
      min: false,
      show: true,
      total: false,
      values: false,
    },
    lines: true,
    linewidth: 1,
    links: [],
    nullPointMode: "null as zero",
    percentage: false,
    pointradius: 5,
    points: false,
    renderer: "flot",
    seriesOverrides: [],
    spaceLength: 10,
    span: 6,
    stack: false,
    steppedLine: false,
    targets: [],
    thresholds: [],
    timeFrom: null,
    timeShift: null,
    title: title,
    tooltip: {
      shared: true,
      sort: 0,
      value_type: "individual",
    },
    type: "graph",
    xaxis: {
      buckets: null,
      mode: "time",
      name: null,
      show: true,
      values: [],
    },
    yaxes: $.yaxes("short"),
  },

  stack:: {
    stack: true,
    fill: 10,
    linewidth: 0,
  },

  yaxes(format):: [
    {
      format: format,
      label: null,
      logBase: 1,
      max: null,
      min: 0,
      show: true,
    },
    {
      format: "short",
      label: null,
      logBase: 1,
      max: null,
      min: null,
      show: false,
    },
  ],

  qpsPanel(selector):: {
    aliasColors: {
      "1xx": "#EAB839",
      "2xx": "#7EB26D",
      "3xx": "#6ED0E0",
      "4xx": "#EF843C",
      "5xx": "#E24D42",
      success: "#7EB26D",
      "error": "#E24D42",
    },
    targets: [
      {
        expr: "sum by (status) (label_replace(label_replace(rate(" + selector + "[1m]),"
          + " \"status\", \"${1}xx\", \"status_code\", \"([0-9])..\"),"
          + " \"status\", \"${1}\",   \"status_code\", \"([a-z]+)\"))",
        format: "time_series",
        intervalFactor: 2,
        legendFormat: "{{status}}",
        refId: "A",
        step: 10,
      },
    ],
  } + $.stack,

  latencyPanel(metricName, selector, multiplier="1e3"):: {
    nullPointMode: "connected",
    targets: [
      {
        expr: "histogram_quantile(0.99, sum(rate(%s_bucket%s[5m])) by (le)) * %s" % [metricName, selector, multiplier],
        format: "time_series",
        intervalFactor: 2,
        legendFormat: "99th Percentile",
        refId: "A",
        step: 10,
      },
      {
        expr: "histogram_quantile(0.50, sum(rate(%s_bucket%s[5m])) by (le)) * %s" % [metricName, selector, multiplier],
        format: "time_series",
        intervalFactor: 2,
        legendFormat: "50th Percentile",
        refId: "B",
        step: 10,
      },
      {
        expr: "sum(rate(%s_sum%s[5m])) * %s / sum(rate(%s_count%s[5m]))" % [metricName, selector, multiplier, metricName, selector],
        format: "time_series",
        intervalFactor: 2,
        legendFormat: "Average",
        refId: "C",
        step: 10,
      },
    ],
    yaxes: $.yaxes("ms"),
  },

  queryPanel(query, legend):: {
    targets: [
      {
        expr: query,
        format: "time_series",
        intervalFactor: 2,
        legendFormat: legend,
        refId: "A",
        step: 10,
      },
    ],
  },

  addPanel(panel):: {
    panels+: [panel],
  },
}
