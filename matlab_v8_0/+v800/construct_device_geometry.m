function [spec, netGeometry] = construct_device_geometry(deviceName)
%CONSTRUCT_DEVICE_GEOMETRY Canonical device geometry wrapper.

spec = make_device_spec(deviceName);
netGeometry = build_hallbar_network(spec);

end

