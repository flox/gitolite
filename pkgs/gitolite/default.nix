{ self
, stdenv
, coreutils
, fetchFromGitHub
, gawk
, git
, lib
, makeWrapper
, nettools
, openssh
, perl
, perlPackages
, nixosTests }:

stdenv.mkDerivation rec {
  pname = "gitolite";
  version = "3.6.12";
  src = self; # + "/src";

  buildInputs = [ nettools perl ];
  nativeBuildInputs = [ makeWrapper ];
  propagatedBuildInputs = [ git ];

  dontBuild = true;

  postPatch = ''
    substituteInPlace ./install --replace " 2>/dev/null" ""
    substituteInPlace src/lib/Gitolite/Hooks/PostUpdate.pm \
      --replace /usr/bin/perl "${perl}/bin/perl"
    substituteInPlace src/lib/Gitolite/Hooks/Update.pm \
      --replace /usr/bin/perl "${perl}/bin/perl"
    substituteInPlace src/lib/Gitolite/Setup.pm \
      --replace hostname "${nettools}/bin/hostname"
    substituteInPlace src/commands/sskm \
      --replace /bin/rm "${coreutils}/bin/rm"
  '';

  postFixup = ''
    wrapProgram $out/bin/gitolite-shell \
      --prefix PATH : ${lib.makeBinPath [ gawk git openssh (perl.withPackages (p: [ p.JSON ])) ]}
  '';

  installPhase = ''
    mkdir -p $out/bin
    perl ./install -to $out/bin
    echo ${version} > $out/bin/VERSION
  '';

  passthru.tests = {
    gitolite = nixosTests.gitolite;
  };

  meta = with lib; {
    description = "Finely-grained git repository hosting";
    homepage    = "https://gitolite.com/gitolite/index.html";
    license     = licenses.gpl2;
    platforms   = platforms.unix;
    maintainers = [ maintainers.thoughtpolice maintainers.lassulus maintainers.tomberek ];
  };
}
