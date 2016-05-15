#!/usr/bin/env perl

use v5.18;
use strict;
use warnings;

use Data::Dumper::Concise; # For Dumper().

use Mojo::DOM;

# ----------------------------

my($html) =
q|
<body>
<h2><span class="mw-headline" id="Uses_and_applications">Uses and applications</span><span class="mw-editsection"><span class="mw-editsection-bracket">[</span><a href="/w/index.php?title=ISO_3166-1_alpha-3&amp;action=edit&amp;section=1" title="Edit section: Uses and applications">edit</a><span class="mw-editsection-bracket">]</span></span></h2>
<p>The ISO 3166-1 alpha-3 codes are used most prominently in ISO/<a href="/wiki/International_Electrotechnical_Commission" title="International Electrotechnical Commission">IEC</a> 7501-1 for <a href="/wiki/Machine-readable_passport" title="Machine-readable passport">machine-readable passports</a>, as standardized by the <a href="/wiki/International_Civil_Aviation_Organization" title="International Civil Aviation Organization">International Civil Aviation Organization</a>, with a number of additional codes for special passports; some of these codes are currently <a href="#Codes_currently_agreed_not_to_use">reserved and not used at the present stage</a> in ISO 3166-1.<sup id="cite_ref-icao_2-0" class="reference"><a href="#cite_note-icao-2">[2]</a></sup></p>
<p>The <a href="/wiki/United_Nations" title="United Nations">United Nations</a> uses a combination of ISO 3166-1 alpha-2 and alpha-3 codes, along with codes that pre-date the creation of ISO 3166, for <a href="/wiki/List_of_international_vehicle_registration_codes" title="List of international vehicle registration codes">international vehicle registration codes</a>, which are codes used to identify the issuing country of a vehicle registration plate; some of these codes are currently <a href="#Indeterminate_reservations">indeterminately reserved</a> in ISO 3166-1.<sup id="cite_ref-3" class="reference"><a href="#cite_note-3">[3]</a></sup></p>
<h2><span class="mw-headline" id="Current_codes">Current codes</span><span class="mw-editsection"><span class="mw-editsection-bracket">[</span><a href="/w/index.php?title=ISO_3166-1_alpha-3&amp;action=edit&amp;section=2" title="Edit section: Current codes">edit</a><span class="mw-editsection-bracket">]</span></span></h2>
<h3><span class="mw-headline" id="Officially_assigned_code_elements">Officially assigned code elements</span><span class="mw-editsection"><span class="mw-editsection-bracket">[</span><a href="/w/index.php?title=ISO_3166-1_alpha-3&amp;action=edit&amp;section=3" title="Edit section: Officially assigned code elements">edit</a><span class="mw-editsection-bracket">]</span></span></h3>
<p>The following is a complete list of the current officially assigned ISO 3166-1 alpha-3 codes, using the English short country names officially defined by the ISO 3166 Maintenance Agency (ISO 3166/MA):<sup id="cite_ref-4" class="reference"><a href="#cite_note-4">[4]</a></sup></p>
<table>
	<tr>
		<td>
			<table>
				<tr>
<td style="width:2.5em;"><span style="font-family: monospace, monospace;">ABW</span></td>
<td><a href="/wiki/Aruba" title="Aruba">Aruba</a></td>
				</tr>
			</table>
		</td>
		<td>
			<table>
				<tr>
<td><span style="font-family: monospace, monospace;">AFG</span></td>
<td><a href="/wiki/Afghanistan" title="Afghanistan">Afghanistan</a></td>
				</tr>
			</table>
		</td>
	</tr>
</table>
</body>
|;
my($dom)	= Mojo::DOM -> new($html);
my($count)	= -1;
my($codes)	= [];

my($content, $code);

for my $node ($dom -> at('table') -> descendant_nodes -> each)
{
	$count++;

	if ($node -> matches('span'))
	{
		$content = $node -> content;

		$code = {code => $content, name => ''};
	}
	elsif ($node -> matches('a') )
	{
		$content = $node -> content;

		$$code{name} = $content;

		push @$codes, $code;
	}
}

say '-' x 50, "\n", Dumper(@$codes);
