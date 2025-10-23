import { HoneycombWebSDK } from '@honeycombio/opentelemetry-web'
import { getWebAutoInstrumentations } from '@opentelemetry/auto-instrumentations-web'
import { trace } from '@opentelemetry/api'

export function initTelemetry() {
  const sdk = new HoneycombWebSDK({
    apiKey: import.meta.env.VITE_HONEYCOMB_API_KEY,
    serviceName: 'order-processing-service',
    instrumentations: [
      getWebAutoInstrumentations({
        '@opentelemetry/instrumentation-fetch': {
          propagateTraceHeaderCorsUrls: /.*/,
          clearTimingResources: true
        },
        '@opentelemetry/instrumentation-xml-http-request': {
          propagateTraceHeaderCorsUrls: /.*/
        }
      })
    ]
  })

  sdk.start()
}

export const tracer = trace.getTracer('order-processing-service')
