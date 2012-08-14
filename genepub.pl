#!/usr/bin/perl

#print "base dir: $basedir\n";

sub GetFiles {
	my $f = $_[0];
	my @result;
	my $str;
	
	open(HANDLE, $f);
	while(<HANDLE>) {
		if(/<img .*src=(.*?)\s.*>/) {
			$str = $1;
			$str =~ s/\"//g;
			push(@result, $str);
		}
	}
	return @result;
}

sub GetCSSFiles {
	my $f = $_[0];
	my @result;
	my $str;
	
	open(HANDLE, $f);
	while(<HANDLE>) {
		if(/url\((.*)\)/) {
			$str = $1;
			$str =~ s/\"//g;
			$str =~ s/\'//g;
#			print "$str\n";
			push(@result, $str);
		}
	}
	return @result;
}

sub GetMediaType {
	my $ext = $_[0];
	
	$ext =~ s/.//;
	if($ext eq 'jpg') {
		return "image/jpeg";
	}
	elsif($ext eq 'png') {
		return "image/png";
	}
	elsif($ext eq 'svg') {
		return "image/svg+xml";
	}
	elsif($ext eq 'ttf') {
		return "application/x-font-ttf";	
	}
	return "text/html";
}

sub txt2xhtml {
	my $epubname = shift;
	my $fname = shift;
	my $title = shift;
	my $subtitle = shift;
	my $lang = shift;
	
	my ($base, $dirname, $ext) = fileparse($fname, qr/\.[^.]*/);
	$xmlfile = ">$epubname/OEPBS/$base.xhtml";
	open(FILE, $fname) or die "Can't open file: $fname\n";
	open(OUT, $xmlfile);
	
	# Print header
	print OUT "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
	print OUT "<!DOCTYPE html>\n";
	print OUT "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"$lang\">\n";
	print OUT "<head>\n";
	print OUT "    <meta charset=\"utf-8\" />\n";
	print OUT "    <title>$title</title>\n";
	print OUT "    <link href=\"default.css\" rel=\"stylesheet\" type=\"text/css\" />\n";
	print OUT "</head>\n";
	print OUT "<body>\n";

	$inp = 0;
	if($title ne '') {
		print OUT "<h5>$title</h5>\n";
	}
	if($subtitle ne '') {
		print OUT "<h3>$subtitle</h3>\n";
	}
	while(<FILE>) {
		chomp($_);
		if(($_ eq '') && ($inp == 1)) {
			print OUT "</span></p>\n";
			$inp = 0;
		}
		else {
			if($inp == 0) {
				print OUT "<p dir=\"rtl\"><span class=\"regular\">\n";
				$inp = 1;
			}
			print OUT "$_<br />\n";
		}
	}
	if($inp) {
		print OUT "</span></p>\n";
	}
	print OUT "</body>\n";
	print OUT "</html>\n";
	close(OUT);
	close(FILE);
}

sub CreateCover {
	my $epubname = shift;
	my $lang = shift;
	my $image = shift;
	my $copyright = shift;
	
	open(FILE, ">$epubname/OEPBS/cover.xhtml") or die "Unable to create cover.xhtml";
	print FILE "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
	print FILE "<!DOCTYPE html>\n";
	print FILE "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"$lang\">\n";
	print FILE "<head>\n<meta charset=\"utf-8\" />\n";
	print FILE "<meta name=\"Copyright\" xml:lang=\"$lang\" content=\"$copyright\" />\n";
	print FILE "<title>$title</title>\n";
	print FILE "<link href=\"default.css\" rel=\"stylesheet\" type=\"text/css\" />\n";
	print FILE "</head>\n<body>\n";
	print FILE "<div style=\"text-align:center;page-break-after:always;\">\n";
	my ($base, $dirname) = fileparse($image);
	copy($image, "$epubname/OEPBS/");
	print FILE "<img src=\"$base\" style=\"height:100%;\" alt=\"Cover image\" />\n";
	print FILE "</div>\n</body>\n</html>\n";
	close(FILE);
	if($lang eq "he") {
		$title = "דף פתיחה";
	}
	else {
		$title = "Cover page";
	}
	return "cover.xhtml,$title,";
}

sub CreateCopyright {
	my $epubname = shift;
	my $lang = shift;
	my $copyright = shift;
	my $title = shift;
	my $copyrightlogo = shift;
	my $text = shift;

	open(FILE, ">$epubname/OEPBS/copyright.xhtml");
	print FILE "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
	print FILE "<!DOCTYPE html>\n";
	print FILE "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"$lang\">\n";
	print FILE "<head>\n<meta charset=\"utf-8\" />\n";
	print FILE "<meta name=\"Copyright\" xml:lang=\"$lang\" content=\"$copyright\" />\n";
	print FILE "<title>$title</title>\n";
	print FILE "<link href=\"default.css\" rel=\"stylesheet\" type=\"text/css\" />\n";
	print FILE "</head>\n<body>\n";
	if($lang eq "he") {
		print FILE "<div dir=\"rtl\">\n";
	}
	else {
		print FILE "<div>\n";
	}
	print FILE "<br /><br />\n";
	my ($base, $dirname) = fileparse($copyrightlogo);
	copy($copyrightlogo, "$epubname/OEPBS/");
	print FILE "<img src=\"$base\" alt=\"Copyright logo\" />\n";
	$text =~ s/\\n/\<br \/\>\n/g;
	print FILE $text;
	print FILE "</div>\n</body>\n</html>\n";
	close(FILE);
	if($lang eq "he") {
		$title = "זכויות יוצרים";
	}
	else {
		$title = "Copyright";
	}
	return "copyright.xhtml,$title,";
}

sub CreateDirs {
	my $epubname = $_[0];
	print "Generating directory: $epubname\n";
	mkdir $epubname;
	print "Generating directory: $epubname/OEPBS\n";
	mkdir "$epubname/OEPBS";
	mkdir "$epubname/OEPBS/Fonts";
	
	print "Generating file: mimetype\n";
	open(MIME, ">$epubname/mimetype");
	print MIME "application/epub+zip";
	close(MIME);
	
	print "Generating directory META-INF\n";
	mkdir "$epubname/META-INF";
	open(CONTAINER, ">$epubname/META-INF/container.xml");
	print CONTAINER "<?xml version=\"1.0\"?>\n";
	print CONTAINER "<container version=\"1.0\" xmlns=\"urn:oasis:names:tc:opendocument:xmlns:container\">\n";
	print CONTAINER "<rootfiles>\n";
	print CONTAINER "<rootfile full-path=\"OEPBS/content.opf\" media-type=\"application/oebps-package+xml\"/>\n";
	print CONTAINER "</rootfiles>\n</container>\n";
	close(CONTAINER);
}

sub CreateToc {
	my $epubname = shift;
	my $identifier = shift;
	my $title = shift;
	my $author = shift;
	my $lang = shift;
	my @files = @_;
	my $cword;
	my ($base, $dirname, $ext);

	open(TOC, ">$epubname/OEPBS/toc.xhtml");
	print TOC "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
	print TOC "<html xmlns=\"http://www.w3.org/1999/xhtml\">\n";
	print TOC "<head>\n";
	print TOC "<meta charset=\"utf-8\" />\n";
	print TOC "<link rel=\"stylesheet\" href=\"default.css\" type=\"text/css\" />\n";
	print TOC "<title>$title</title>\n";
	print TOC "</head>\n";
	print TOC "<body>\n";
	print TOC "<section class=\"toc\">\n";
	print "lang: $lang\n";
	if($lang =~ /he/) {
		$cword = "תוכן העניינים";
	}
	else {
		$cword = "Table of contents";
	}
	print TOC "<header>\n<h1>$cword</h1>\n</header>\n";
	print TOC "<nav xmlns:epub=\"http://www.idpf.org/2007/ops\" epub:type=\"toc\" id=\"toc\">\n";
	print TOC "<ol>\n";

	open(NCX, ">$epubname/OEPBS/toc.ncx");
	print NCX "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
	print NCX "<!DOCTYPE ncx PUBLIC \"-//NISO//DTD ncx 2005-1//EN\" \"http://www.daisy.org/z3986/2005/ncx-2005-1.dtd\">\n";
	print NCX "<ncx xmlns=\"http://www.daisy.org/z3986/2005/ncx/\" version=\"2005-1\">\n";
	print NCX "<head>\n";
	print NCX "<meta name=\"dtb:uid\" content=\"$identifier\"/>\n";
	print NCX "<meta name=\"dtb:depth\" content=\"1\"/>\n";
	print NCX "<meta name=\"dtb:totalPageCount\" content=\"0\"/>\n";
	print NCX "<meta name=\"dtb:maxPageNumber\" content=\"0\"/>\n";
	print NCX "</head>\n";
	print NCX "<docTitle>\n<text>$title</text>\n</docTitle>\n";
	print NCX "<docAuthor>\n<text>$author</text>\n</docAuthor>\n";
	print NCX "<navMap>\n";

	my $ord = 1;
	foreach(@files) {
		($fname,$title,$subtitle) = split(/,/, $_);
		($base, $dirname, $ext) = fileparse($fname, qr/\.[^.]*/);	

		if($subtitle eq '') {
			$subtitle = $title;
		}
		if($subtitle eq '') {
			$subtitle = $base;
		}
		
		print TOC "<li id=\"$base\"><a href=\"$base.xhtml\">$subtitle</a></li>\n";

		print NCX "<navPoint class=\"chapter\" id=\"$base\" playOrder=\"$ord\">\n";
		print NCX "<navLabel>\n<text>$subtitle</text>\n</navLabel>\n";
		print NCX "<content src=\"$base.xhtml\" />\n";
		print NCX "</navPoint>\n";
		$ord++;
	}
	print NCX "</navMap>\n";
	print NCX "</ncx>\n";
	close(NCX);

	print TOC "</ol>\n</nav>\n</section>\n</body>\n</html>\n";
	close(TOC);
}

my($epubname, %metadata, %cover, @files);
print "Opening content.txt\n";
open(FILE, "content.txt");
while(<FILE>) {
	if(/^.F,(.*)/) {
		$epubname = $1;
	}
	elsif(/^.M\[(.*)\](.*)/) {
		$metadata{$1} = $2;
	}
	elsif(/^.C\[(.*)\](.*)/) {
		$cover{$1} = $2;
	}
	else {
		push(@files, $_);
	}
}
close(FILE);

CreateDirs($epubname);
$fname = CreateCopyright($epubname, $metadata{"language"}, $metadata{"rights"}, $metadata{"title"}, $cover{"licenselogo"}, $cover{"license"});
unshift(@files, $fname);

my $fname = CreateCover($epubname, $metadata{"language"}, $cover{"image"}, $metadata{"rights"});
unshift(@files, $fname);

CreateToc($epubname, $metadata{"identifier"}, $metadata{"title"}, $metadata{"author"}, $metadata{"language"}, @files);

print "Generating content.opf\n";
open(CONTENT, ">$epubname/OEPBS/content.opf");		
print CONTENT "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print CONTENT "<package xmlns=\"http://www.idpf.org/2007/opf\" version=\"3.0\" unique-identifier=\"bookid\">\n";
print CONTENT "<metadata xmlns:opf=\"http://www.idpf.org/2007/opf\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\">\n";
my $meta = 1;
my $metaname;
my $metacontent;
while(($metaname, $metacontent) = each(%metadata)) {
	if($metaname eq "identifier") {
		print CONTENT "<dc:identifier id=\"bookid\">$metacontent</dc:identifier>\n";
		print CONTENT "<meta property=\"dcterms:$metaname\">$metacontent</meta>\n";
	}
	else {
		print CONTENT "<dc:$metaname>$metacontent</dc:$metaname>\n";
		print CONTENT "<meta property=\"dcterms:$metaname\">$metacontent</meta>\n";
	}
}
my $strtime = strftime('%Y-%m-%dT%H:%M:%SZ', localtime);
print CONTENT "<meta property=\"dcterms:modified\">$strtime</meta>\n";

print CONTENT "</metadata>\n";
print CONTENT "<manifest>\n";
print CONTENT "<item id=\"ncx\" href=\"toc.ncx\" media-type=\"application/x-dtbncx+xml\"/>\n";
print CONTENT "<item id=\"toc\" properties=\"nav\" href=\"toc.xhtml\" media-type=\"application/xhtml+xml\" />\n";
copy("$basedir/default.css", "$epubname/OEPBS/default.css");
print CONTENT "<item id=\"css\" href=\"default.css\" media-type=\"text/css\"/>\n";
@additionalfiles = GetCSSFiles("$basedir/default.css");
foreach(@additionalfiles) {
	($b, $d, $e) = fileparse($_, qr/\.[^.]*/);
	print "Copy $_ to $epubname/OEPBS/$d$b$e\n";
	copy("$basedir/$_", "$epubname/OEPBS/$d/$b$e");
	$mt = GetMediaType($e);
	print CONTENT "<item id=\"$b\" href=\"$_\" media-type=\"$mt\" />\n";
}
my $f = $cover{"image"};
my($dirname, $base, $ext);
if($f) {
	($base, $dirname, $ext) = fileparse($f, qr/\.[^.]*/);
	$mt = GetMediaType($ext);
	print CONTENT "<item id=\"coverimg\" href=\"$base$ext\" media-type=\"$mt\" />\n";
}
$f = $cover{"licenselogo"};
if($f) {
	($base, $dirname, $ext) = fileparse($f, qr/\.[^.]*/);
	$mt = GetMediaType($ext);
	print CONTENT "<item id=\"licenselogo\" href=\"$base$ext\" media-type=\"$mt\" />\n";
}

my($d, $b, $e);
my(@spine);
foreach(@files) {
	($fname, $title, $subtitle) = split(/,/, $_);
	($base, $dirname, $ext) = fileparse($fname, qr/\.[^.]*/);
	if($ext eq ".xhtml") {
		print CONTENT "<item id=\"$base\" href=\"$base.xhtml\" media-type=\"application/xhtml+xml\"/>\n";
		push(@spine, $base);
	}
	elsif($ext eq ".txt") {
		@additionalfiles = GetFiles($fname);
		txt2xhtml($epubname, $fname, $title, $subtitle, $metadata{"language"});
		print CONTENT "<item id=\"$base\" href=\"$base.xhtml\" media-type=\"application/xhtml+xml\"/>\n";
		push(@spine, $base);
		foreach(@additionalfiles) {
			($b, $d, $e) = fileparse($_, qr/\.[^.]*/);
			copy($_, "$epubname/OEPBS/");
			$mt = GetMediaType($e);
			print CONTENT "<item id=\"$b\" href=\"$b$e\" media-type=\"$mt\" />\n";
		}
	}
	elsif($ext eq "jpg") {
		copy($_, "$epubname/OEPBS/$_");
		print CONTENT "<item id=\"$base\" href=\"$base.$ext\" media-type=\"image/jpeg\"/>\n";
	}
	elsif($ext eq "png") {
		copy($_, "$epubname/OEPBS/$_");
		print CONTENT "<item id=\"$base\" href=\"$base.$ext\" media-type=\"image/png\"/>\n";
	}
}
print CONTENT "</manifest>\n";
my $pd;
if($metadata{"language"} eq 'he') {
	$pd = "page-progression-direction=\"rtl\"";
}
else {
	$pd = "page-progression-direction=\"ltr\"";
}
print CONTENT "<spine $pd toc=\"ncx\">\n";

foreach (@spine) {
	print CONTENT "<itemref idref=\"$_\" />\n";
}
print CONTENT "</spine>\n";
print CONTENT "</package>\n";
close(CONTENT);

chdir($epubname);
system("zip -r -X $epubname.zip mimetype META-INF/ OEPBS/");
chdir("..");
system("mv $epubname/$epubname.zip $epubname.epub");

1;

