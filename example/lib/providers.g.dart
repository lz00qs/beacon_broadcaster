// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(beaconRepository)
final beaconRepositoryProvider = BeaconRepositoryProvider._();

final class BeaconRepositoryProvider extends $FunctionalProvider<
        AsyncValue<BeaconRepository>,
        BeaconRepository,
        FutureOr<BeaconRepository>>
    with $FutureModifier<BeaconRepository>, $FutureProvider<BeaconRepository> {
  BeaconRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'beaconRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$beaconRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<BeaconRepository> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<BeaconRepository> create(Ref ref) {
    return beaconRepository(ref);
  }
}

String _$beaconRepositoryHash() => r'7615d2adc7b3c6a5eedb008cf5515a9e1ed3af98';

@ProviderFor(BeaconList)
final beaconListProvider = BeaconListProvider._();

final class BeaconListProvider
    extends $AsyncNotifierProvider<BeaconList, List<Beacon>> {
  BeaconListProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'beaconListProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$beaconListHash();

  @$internal
  @override
  BeaconList create() => BeaconList();
}

String _$beaconListHash() => r'cccbd2496e3313c67fd492fcef687c22d22be395';

abstract class _$BeaconList extends $AsyncNotifier<List<Beacon>> {
  FutureOr<List<Beacon>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Beacon>>, List<Beacon>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<Beacon>>, List<Beacon>>,
        AsyncValue<List<Beacon>>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(Toggle)
final toggleProvider = ToggleProvider._();

final class ToggleProvider extends $NotifierProvider<Toggle, bool> {
  ToggleProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'toggleProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$toggleHash();

  @$internal
  @override
  Toggle create() => Toggle();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$toggleHash() => r'776179f74be43d9601742d397c1a07763f7befe4';

abstract class _$Toggle extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<bool, bool>, bool, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(beaconBroadcaster)
final beaconBroadcasterProvider = BeaconBroadcasterProvider._();

final class BeaconBroadcasterProvider extends $FunctionalProvider<
    BeaconBroadcaster,
    BeaconBroadcaster,
    BeaconBroadcaster> with $Provider<BeaconBroadcaster> {
  BeaconBroadcasterProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'beaconBroadcasterProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$beaconBroadcasterHash();

  @$internal
  @override
  $ProviderElement<BeaconBroadcaster> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BeaconBroadcaster create(Ref ref) {
    return beaconBroadcaster(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BeaconBroadcaster value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BeaconBroadcaster>(value),
    );
  }
}

String _$beaconBroadcasterHash() => r'a176b8b4d9054350adc67294a5da71cd1e69e43c';

@ProviderFor(bluetoothState)
final bluetoothStateProvider = BluetoothStateProvider._();

final class BluetoothStateProvider extends $FunctionalProvider<
        AsyncValue<BluetoothState>, BluetoothState, Stream<BluetoothState>>
    with $FutureModifier<BluetoothState>, $StreamProvider<BluetoothState> {
  BluetoothStateProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'bluetoothStateProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$bluetoothStateHash();

  @$internal
  @override
  $StreamProviderElement<BluetoothState> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<BluetoothState> create(Ref ref) {
    return bluetoothState(ref);
  }
}

String _$bluetoothStateHash() => r'e08bd3d4734afed6f72d2ea1983a9219a5267062';
