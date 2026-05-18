// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_configcat/otel_configcat.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_configcat-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('get_value records setting + variation + matched rule', () async {
    await tracedConfigcat<String>(
      operation: 'setting.get_value_details',
      invoke: () async => const ConfigcatCallResult(
        value: 'ok',
        result: ConfigcatResult(
          settingKey: 'beta-features',
          value: 'true',
          variationId: 'v-1',
          environment: 'prod',
          product: 'main',
          dataGovernance: 'eu_only',
          matchedTargetingRule: 2,
          usedDefault: false,
          fromCache: true,
        ),
      ),
    );
    final a = attrsOf(
      spans.findSpanByName('configcat setting.get_value_details')!,
    );
    expect(a['configcat.setting.key'], 'beta-features');
    expect(a['configcat.variation.id'], 'v-1');
    expect(a['configcat.matched_targeting_rule'], 2);
    expect(a['configcat.data_governance'], 'eu_only');
    expect(a['configcat.from_cache'], true);
  });

  test('used_default sets span error', () async {
    await tracedConfigcat<String>(
      operation: 'setting.get_value',
      invoke: () async => const ConfigcatCallResult(
        value: 'ok',
        result: ConfigcatResult(usedDefault: true),
      ),
    );
    expect(
      spans.findSpanByName('configcat setting.get_value')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutConfigcatInstrumentationAsync(() async {
      await tracedConfigcat<String>(
        operation: 'settings.list',
        invoke: () async => const ConfigcatCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('configcat '), isEmpty);
  });
}
