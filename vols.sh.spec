Name:           vols.sh
Version:        0.0.0
Release:        1%{?dist}
Summary:        Docker External Volume Manager

License:        GPLv3+ 
#URL:            
Source0:        vols.sh-0.0.0.tar.gz

#BuildRequires:  
#Requires:       

%description
Docker External Volume Manager is a simple bash script to
help with managing the external volumes

%global debug_package %{nil}

%prep
%setup -q


%build
echo "building"

%install
install -m 0755 -d $RPM_BUILD_ROOT/usr/bin/
install -m 0755 vols.sh $RPM_BUILD_ROOT/usr/bin/vols.sh

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/usr/bin/vols.sh

#%license add-license-file-here
#%doc add-docs-here


%changelog
* Wed Nov 09 2022 root
    - First Post
