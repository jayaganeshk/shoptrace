
# Queries

# All Events
resource "honeycombio_query" "all_events" {
  dataset = var.honeycomb_dataset
  # name        = "API Performance"
  # description = "Average latency and request count of API paths by function name and status."

  query_json = jsonencode({
    time_range  = 1800
    granularity = 0
    breakdowns = [
      "faas.name",
      "event.processTime",
      "event.path",
      "event.input",
      "event.status",
      "session_id",
      "user.username",
      "error.type",
      "error.message",
      "duration_ms",
    ]
    # calculations = [
    #   { op = "AVG", column = "duration_ms" },
    #   { op = "COUNT", column = null }
    # ]
    filters = [
      { column = "event", op = "exists", value = null }
    ]
    filter_combination = "AND"
    orders             = [{ column = "event.processTime", order = "descending" }]
    limit              = 100
  })
}


# API Performance
resource "honeycombio_query" "api_performance" {
  dataset = var.honeycomb_dataset
  # name        = "API Performance"
  # description = "Average latency and request count of API paths by function name and status."

  query_json = jsonencode({
    time_range  = 1800
    granularity = 0
    breakdowns  = ["faas.name", "event.path", "event.status"]
    calculations = [
      { op = "AVG", column = "duration_ms" },
      { op = "COUNT", column = null }
    ]
    filters = [
      { column = "event", op = "exists", value = null }
    ]
    filter_combination = "AND"
    # orders             = [{ column = "duration_ms", order = "descending" }]
    limit = 100
  })
}

# Error Tracking
resource "honeycombio_query" "error_tracking" {
  dataset = var.honeycomb_dataset
  # name        = "Error Tracking"
  # description = "Counts of errors by function, error type/message and endpoint path."

  query_json = jsonencode({
    time_range  = 1800
    granularity = 0
    breakdowns  = ["faas.name", "error.type", "error.message", "event.path", "event.processTime"]
    calculations = [
      { op = "COUNT", column = null }
    ]
    filters = [
      { column = "error.type", op = "exists", value = null }
    ]
    filter_combination = "AND"
    orders             = [{ column = "event.processTime", order = "descending" }]
    limit              = 50
  })
}

# User Activity
resource "honeycombio_query" "user_activity" {
  dataset = var.honeycomb_dataset
  # name        = "User Activity"
  # description = "Counts of user sessions and endpoints accessed per user."

  query_json = jsonencode({
    time_range = 3600
    # granularity = 0
    breakdowns = ["user.username", "session_id", "event.path"]
    calculations = [
      { op = "COUNT", column = null }
    ]
    filters = [
      { column = "user.username", op = "exists", value = null }
    ]
    filter_combination = "AND"
    # orders             = [{ column = "event.processTime", order = "descending" }]
    limit = 100
  })
}

# Lambda Performance
resource "honeycombio_query" "lambda_performance" {
  dataset = var.honeycomb_dataset
  # name        = "Lambda Performance"
  # description = "Latency metrics (avg, p95) and invocation counts for each Lambda function."

  query_json = jsonencode({
    time_range  = 1800
    granularity = 300
    breakdowns  = ["faas.name"]
    calculations = [
      { op = "AVG", column = "duration_ms" },
      { op = "P95", column = "duration_ms" },
      { op = "COUNT", column = null }
    ]
    filters = [
      { column = "faas.name", op = "exists", value = null }
    ]
    filter_combination = "AND"
    # orders             = [{ column = "duration_ms", order = "descending" }]
    limit = 20
  })
}

############################
# Query Annotations (referenced by flexible board panels)
############################
resource "honeycombio_query_annotation" "all_events" {
  dataset     = var.honeycomb_dataset
  query_id    = honeycombio_query.all_events.id
  name        = "All Events"
  description = "All events processed by the system."
}

resource "honeycombio_query_annotation" "api_performance" {
  dataset     = var.honeycomb_dataset
  query_id    = honeycombio_query.api_performance.id
  name        = "API Performance"
  description = "Average latency and request count of API paths."
}

resource "honeycombio_query_annotation" "error_tracking" {
  dataset     = var.honeycomb_dataset
  query_id    = honeycombio_query.error_tracking.id
  name        = "Error Tracking"
  description = "Errors by function, type/message and endpoint path."
}

resource "honeycombio_query_annotation" "user_activity" {
  dataset     = var.honeycomb_dataset
  query_id    = honeycombio_query.user_activity.id
  name        = "User Activity"
  description = "User sessions and endpoints accessed per user."
}

resource "honeycombio_query_annotation" "lambda_performance" {
  dataset     = var.honeycomb_dataset
  query_id    = honeycombio_query.lambda_performance.id
  name        = "Lambda Performance"
  description = "Latency (avg, p95) and invocation counts per Lambda."
}

############################
# Flexible Board (Dashboard)
############################
resource "honeycombio_flexible_board" "shop_trace_dashboard" {
  name        = "Shop Trace API Dashboard"
  description = "Comprehensive monitoring for Shop Trace service"

  # Row 1 — API (left) & Lambda (right)
  panel {
    type = "query"
    query_panel {
      query_id            = honeycombio_query.api_performance.id
      query_annotation_id = honeycombio_query_annotation.api_performance.id
      query_style         = "graph"
    }
    position {
      x_coordinate = 0
      y_coordinate = 0
      width        = 6
      height       = 6
    }
  }

  panel {
    type = "query"
    query_panel {
      query_id            = honeycombio_query.lambda_performance.id
      query_annotation_id = honeycombio_query_annotation.lambda_performance.id
      query_style         = "combo"
    }
    position {
      x_coordinate = 6
      y_coordinate = 0
      width        = 6
      height       = 6
    }
  }

  # Row 2 — User Activity (left) & Error Tracking (right)
  panel {
    type = "query"
    query_panel {
      query_id            = honeycombio_query.user_activity.id
      query_annotation_id = honeycombio_query_annotation.user_activity.id
      query_style         = "graph"
    }
    position {
      x_coordinate = 0
      y_coordinate = 6
      width        = 6
      height       = 6
    }
  }

  panel {
    type = "query"
    query_panel {
      query_id            = honeycombio_query.error_tracking.id
      query_annotation_id = honeycombio_query_annotation.error_tracking.id
      query_style         = "table"
    }
    position {
      x_coordinate = 6
      y_coordinate = 6
      width        = 6
      height       = 6
    }
  }

  # Row 3 — All Events (full width)
  panel {
    type = "query"
    query_panel {
      query_id            = honeycombio_query.all_events.id
      query_annotation_id = honeycombio_query_annotation.all_events.id
      query_style         = "table"
    }
    position {
      x_coordinate = 0
      y_coordinate = 12
      width        = 12
      height       = 6
    }
  }
}

