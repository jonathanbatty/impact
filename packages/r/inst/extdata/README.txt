impact_r_definitions.zip contains byte-for-byte copies of the immutable __*.R
definition resources. R excludes source filenames beginning with underscores
when it builds a source package, so the installed package reads this archive
after GitHub installation. Run the repository buildfile to regenerate it when
the authoritative definitions are regenerated from the master codelist.
