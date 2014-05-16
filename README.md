# omnibus_chef cookbook

[![Build Status](https://travis-ci.org/meineerde-cookbooks/omnibus_chef.svg?branch=master)](https://travis-ci.org/meineerde-cookbooks/omnibus_chef)

Update your chef client with omnibus! This cookbook can install the omnibus
chef package into your system if you are currently running
via gem install, and it can keep your omnibus install up
to date.

This cookbook is inspired by the [omnibus_updater](https://github.com/hw-cookbooks/omnibus_updater)
cookbook and essentially performs the same function but improves it in
various areas:

* It uses idiomatic Ruby and is way less entangled with callbacks and
  notifications.
* It only performs web requests if absolutely necessary. The omnibus_updater
  cookbook will perform a web request on each execution and will fail if the
  Chef web servive is not reachable for any reason.
* It provides an LWRP for its core functionality, allowing easier and more
  flexible usage in other cookbooks.

## Recipes

### omnibus_chef::default

The default recipe checks some preconditions and then just includes the
`install` cookbook.

### omnibus_chef::install_client

The install cookbook installs the Omnibus Chef client package. By default,
it will install the latest available version of Chef which might not be what
you actually want (you can set the exact version in an attribute, see below).

Also, by default, it will kill the current chef run directly after having
updated the chef version. This is heavily recommended to ensure a clean state
for the following cookbooks. During an update, internal chef libraries may
change, move, or no longer exist. The currently running instance can encounter
unexpected states because of this. To prevent this, the updater will attempt
to kill the Chef instance so that it can be restarted in a normal state.

Please see the [Attributes](#Attributes) section below options
to configure this behavior.

### omnibus_chef::remove_system_gem

This optional recipe removes the chef gem if it is installed to the system
ruby. This might be useful if Chef was installed as a system gem once and you
are now migrating to an Omnibus based install.

## Attributes

All attributes are namespaced under `node['omnibus_chef']`. The full
attribute name is thus e.g. `node['omnibus_chef']['version']`.

You can override any of these attributes

<table>
  <tr><th>Attribute</th><th>Default</th><th>Description</th></tr>
  <tr>
    <td><code>download_url</code></td>
    <td><code>nil</code></td>
    <td>
      When set to a full URL, we will use this to download the Omnibus
      package. We will then ignore all the the version  and platform settings.
      The URL must provide the correct package for the current platform and
      machine as well as the correct expected package format (e.g.
      <code>.deb</code> on Debian/Ubuntu).

      By default, this is unset and we determine the correct URL from the
      specified version and download the package directly from
      https://www.getchef.com if required.

      If this is set explicitly, we try to determine the version of the
      package from the URL. It is expected, that it contains the string
      <code>chef_&lt;VERSION&gt;</code>.
    </td>
  </tr>
  <tr>
    <td><code>version</code></td>
    <td><code>"latest"</code></td>
    <td>
      Set the exact vesion to install or <code>"latest"</code> to install the
      latest version available.

      When defining <code>"latest"</code>, a web request to the
      https://getchef.com site always be performed during each chef run.
      Generally, you will want to override this and set your desired version.
    </td>
  </tr>
  <tr>
    <td><code>prerelease</code></td>
    <td><code>false</code></td>
    <td>
      If set to <code>true</code>, pre-release versions of chef-client might
      also be installed if they match the <code>version</code> constraint.
    </td>
  </tr>
  <tr>
    <td><code>machine</code></td>
    <td>the architecture for the <a href="http://docs.opscode.com/api_omnitruck.html">Omnitruck API</a></td>
    <td>
      We try to set this automatically based on information from Ohai. If
      required, you can override it to set the desired architecture, but it
      should generally not be necessary to touch this.

      See http://docs.opscode.com/api_omnitruck.html for details.
    </td>
  </tr>
  <tr>
    <td><code>platform</code></td>
    <td>the current platform for the <a href="http://docs.opscode.com/api_omnitruck.html">Omnitruck API</a></td>
    <td>
      We try to set this automatically based on information from Ohai. If
      required, you can override it to set the desired platform, but it should
      generally not be necessary to touch this.

      See http://docs.opscode.com/api_omnitruck.html for details.
    </td>
  </tr>
  <tr>
    <td><code>platform_version</code></td>
    <td>the current platform version for the <a href="http://docs.opscode.com/api_omnitruck.html">Omnitruck API</a></td>
    <td>
      We try to set this automatically based on information from Ohai. If
      required, you can override it to set the desired platform version,
      but it should generally not be necessary to touch this.

      See http://docs.opscode.com/api_omnitruck.html for details.
    </td>
  </tr>
  <tr>
    <td><code>use_https</code></td>
    <td><code>true</code></td>
    <td>
      Set to <code>true</code> to contact the Omnitruck API via https. This
      ensures that all information with the API (including the download of the
      package to be installed) is retreived via https.

      You should generally keep this enabled unless there is a need to
      intercept the communication (e.g. with a transparent proxy).
    </td>
  </tr>
  <tr>
    <td><code>prevent_downgrade</code></td>
    <td><code>false</code></td>
    <td>
      Set to <code>true</code> to prevent the installation of a lower version
      than is currently installed.
    </td>
  </tr>
  <tr>
    <td><code>when</code></td>
    <td><code>"immediately"</code></td>
    <td>
      This attribute determines when in a Chef run the package should be
      updated.

      If this is set to <code>"immediately"</code>, the upgrade is performed
      where the <code>omnibus_chef::install_client</code> recipe heppens to
      be in the runlist.

      If set to <code>"delayed"</code>, the update is performed at the end of
      the chef run. The current run thus is performed with the version of
      chef that is on the system during the start of the run.
    </td>
  </tr>
  <tr>
    <td><code>kill_chef_on_upgrade</code></td>
    <td><code>true</code></td>
    <td>
      When updating immediately (i.e. if the <code>when</code> attribute is
      set to <code>"immediately"</code>, this ensures that the the current
      chef run is killed after an update to ensure a clean state for the
      following cookbooks.

      During an update, internal chef libraries may change, move, or no
      longer exist. The currently running instance can encounter unexpected
      states because of this. To prevent this, the updater will attempt to
      kill the Chef instance so that it can be restarted in a normal state.

      If <code>when</code> is set to <code>"delayed"</code>, this attribute
      has no effect. The chef run is then not killed as it ends anyway after
      the final delayed notifications have finished to run.
    </td>
  </tr>
  <tr>
    <td><code>restart_chef_client_service</code></td>
    <td><code>false</code></td>
    <td>
      If set to <code>true</code>, the <code>chef-client</code> service is
      restarted after an upgrade. If you use chef as a service, it is a good
      idea to set this to <code>true</code>.
    </td>
  </tr>
</table>

## License

Copyright 2014 Holger Just

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
