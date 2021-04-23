# Workaround LP 1925373

[LP 1925373](https://bugs.launchpad.net/tripleo/+bug/1925373)
will break your cephadm deployments becuase the clients
are configured before the servers.

We think this is because deploy-steps.j2 was 
[changed](https://github.com/openstack/tripleo-heat-templates/commit/ef240c1f62a6afb584ef111fbef2f027a474414f)
to use to use list_concat_unique instead of yaql.

This workaround brings in a 
[new implementation](https://review.opendev.org/c/openstack/heat/+/787662/3/heat/engine/hot/functions.py)
of list_concat_unique.

