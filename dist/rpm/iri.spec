%define            _java_dir    /usr/share/java
%define            _iri_dir     /var/lib/iri
%define            _iri_cfg_dir /etc/iri
%define            _sys_cfg_dir /etc/sysconfig
%define            _systemd_dir /usr/lib/systemd/system

Name:              iri
Version:           1.4.1.6
Release:           1%{?dist}
Summary:           IOTA Reference Implementation
Group:             Applications/System
License:           GPL
URL:               https://github.com/iotaledger/%{name}
Source:            https://github.com/iotaledger/%{name}/archive/v%{version}.tar.gz
BuildRoot:         %{_topdir}/%{name}-%{version}-%{release}-root
BuildArch:         x86_64
Requires:          java >= 1.8.0
BuildRequires:     libappindicator
BuildRequires:     maven
BuildRequires:     systemd
Requires(post):    systemd
Requires(preun):   systemd
Requires(postun):  systemd
AutoReqProv:       no

%description
IOTA Reference Implementation
 
%prep
%setup -q -n %{name}-%{version}
 
%build
cd %{_builddir}/%{name}-%{version}
mvn clean compile
mvn package

%install
mkdir -p $RPM_BUILD_ROOT%{_systemd_dir}
mkdir -p $RPM_BUILD_ROOT%{_sys_cfg_dir}
mkdir -p $RPM_BUILD_ROOT%{_iri_cfg_dir}
mkdir -p $RPM_BUILD_ROOT%{_java_dir}
mkdir -p $RPM_BUILD_ROOT%{_iri_dir}
install -m640 %{_builddir}/%{name}-%{version}/target/%{name}-%{version}.jar $RPM_BUILD_ROOT%{_java_dir}/iri.jar
install -m640 %{_sourcedir}/%{name}.sysconfig $RPM_BUILD_ROOT%{_sys_cfg_dir}/%{name}
install -m640 %{_sourcedir}/%{name}.ini $RPM_BUILD_ROOT%{_iri_cfg_dir}/
install -m644 %{_sourcedir}/%{name}.service $RPM_BUILD_ROOT%{_systemd_dir}/

%files
%defattr(644,root,%{name},750)
%attr(640,root,%{name}) %{_java_dir}/iri.jar
%attr(700,%{name},%{name}) %{_iri_dir}
%attr(700,%{name},%{name}) %{_iri_cfg_dir}
%config %{_systemd_dir}/iri.service
%config(noreplace) %{_sys_cfg_dir}/iri
%config(noreplace) %{_iri_cfg_dir}/iri.ini

%pre
getent group %{name} >/dev/null || groupadd -r %{name}
getent passwd %{name} >/dev/null || useradd -r -g %{name} -G %{name} -d %{_iri_dir} -s /sbin/nologin -c "%{name}" %{name}

%post
%systemd_post iri.service

%preun
%systemd_preun iri.service

%postun
%systemd_postun_with_restart iri.service

%changelog
* Sat Jan 13 2018 Nuriel Shem-Tov <nurielst@hotmail.com>
- Updated systemd and configuration files

* Mon Dec 18 2017 Nuriel Shem-Tov <nurielst@hotmail.com>
- Initial spec creation
