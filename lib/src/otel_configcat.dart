// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_configcat_suppression.dart';

const _tracerName = 'dartastic_otel_libs_configcat';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class ConfigcatResult {
  const ConfigcatResult({
    this.settingKey,
    this.value,
    this.variationId,
    this.environment,
    this.product,
    this.dataGovernance,
    this.matchedTargetingRule,
    this.matchedPercentageOption,
    this.usedDefault,
    this.fromCache,
    this.requestId,
    this.statusCode,
  });

  /// Setting (flag) key.
  final String? settingKey;

  /// Returned value (`on` / `off` / number / string — coerced).
  final String? value;

  /// `variationId` (analytics correlation id) returned by SDK.
  final String? variationId;

  /// Environment slug.
  final String? environment;

  /// Product slug (top-level grouping above configs).
  final String? product;

  /// `global` / `eu_only` — ConfigCat's data-governance setting,
  /// drives CDN region.
  final String? dataGovernance;

  /// Targeting rule index that matched (1-based, `null` if none).
  final int? matchedTargetingRule;

  /// Percentage-option index that matched.
  final int? matchedPercentageOption;

  /// True when SDK returned the supplied default (config error or
  /// empty cache).
  final bool? usedDefault;

  /// Whether served from in-memory cache.
  final bool? fromCache;

  /// `cf-ray` from the ConfigCat CDN.
  final String? requestId;

  final int? statusCode;
}

class ConfigcatCallResult<T> {
  const ConfigcatCallResult({required this.value, this.result});
  final T value;
  final ConfigcatResult? result;
}

/// Wraps a ConfigCat API call in a CLIENT span. [operation] is one of
/// `setting.get_value`, `setting.get_value_details`, `settings.list`,
/// `settings.create`, `settings.update`, `targeting.update`,
/// `segments.list`, `environments.list`, `products.list`,
/// `tags.list`, `webhooks.create`.
Future<T> tracedConfigcat<T>({
  required String operation,
  required Future<ConfigcatCallResult<T>> Function() invoke,
}) async {
  if (configcatInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'configcat',
    'rpc.method': operation,
    'configcat.operation': operation,
  };

  final span = _tracer().startSpan(
    'configcat $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.settingKey != null) {
        extras.add(OTel.attributeString(
          'configcat.setting.key',
          r.result!.settingKey!,
        ));
      }
      if (r.result!.value != null) {
        extras.add(OTel.attributeString(
          'configcat.value',
          r.result!.value!,
        ));
      }
      if (r.result!.variationId != null) {
        extras.add(OTel.attributeString(
          'configcat.variation.id',
          r.result!.variationId!,
        ));
      }
      if (r.result!.environment != null) {
        extras.add(OTel.attributeString(
          'configcat.environment',
          r.result!.environment!,
        ));
      }
      if (r.result!.product != null) {
        extras.add(OTel.attributeString(
          'configcat.product',
          r.result!.product!,
        ));
      }
      if (r.result!.dataGovernance != null) {
        extras.add(OTel.attributeString(
          'configcat.data_governance',
          r.result!.dataGovernance!,
        ));
      }
      if (r.result!.matchedTargetingRule != null) {
        extras.add(OTel.attributeInt(
          'configcat.matched_targeting_rule',
          r.result!.matchedTargetingRule!,
        ));
      }
      if (r.result!.matchedPercentageOption != null) {
        extras.add(OTel.attributeInt(
          'configcat.matched_percentage_option',
          r.result!.matchedPercentageOption!,
        ));
      }
      if (r.result!.usedDefault != null) {
        extras.add(OTel.attributeBool(
          'configcat.used_default',
          r.result!.usedDefault!,
        ));
        if (r.result!.usedDefault == true) {
          span.setStatus(
            SpanStatusCode.Error,
            'ConfigCat returned default value',
          );
        }
      }
      if (r.result!.fromCache != null) {
        extras.add(OTel.attributeBool(
          'configcat.from_cache',
          r.result!.fromCache!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTel.attributeString(
          'configcat.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'ConfigCat HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
