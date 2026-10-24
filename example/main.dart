// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_configcat/otel_configcat.dart';

/// Traces ConfigCat calls with OpenTelemetry.
///
/// `otel_configcat` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each ConfigCat call in
/// [tracedConfigcat]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'configcat-example');

  // Wraps a ConfigCat API call in a CLIENT span.
  final configcatId = await tracedConfigcat<String>(
    operation: 'settings.create',
    invoke: () async {
      // Make the ConfigCat call here, then report what it returned.
      const id = 'configcat_8f3a2c';
      return const ConfigcatCallResult(
          value: id,
          result: ConfigcatResult(
              settingKey: 'orders/2026/inv-1042.pdf',
              variationId: 'variation_8f3a2c',
              environment: 'example',
              product: 'example',
              dataGovernance: 'global',
              matchedTargetingRule: 1,
              matchedPercentageOption: 1,
              usedDefault: true,
              fromCache: true,
              requestId: 'cf-ray',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedConfigcat settings.create returned $configcatId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutConfigcatInstrumentationAsync.
  await runWithoutConfigcatInstrumentationAsync(
    () => tracedConfigcat<String>(
      operation: 'settings.create',
      invoke: () async {
        const id = 'configcat_8f3a2c';
        return const ConfigcatCallResult(
            value: id,
            result: ConfigcatResult(
                settingKey: 'orders/2026/inv-1042.pdf',
                variationId: 'variation_8f3a2c',
                environment: 'example',
                product: 'example',
                dataGovernance: 'global',
                matchedTargetingRule: 1,
                matchedPercentageOption: 1,
                usedDefault: true,
                fromCache: true,
                requestId: 'cf-ray',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
