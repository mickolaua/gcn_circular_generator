This script automaticaly generates the GCN circular draft, which then should be a bit modified (see for fields in <> braces). 
The citation of latest GCNs is included. For a successful run a user needs to install `7z` archiver first. Its executable 
should be globally accessible via PowerShell. This is done by adding the path to `7z` to `$PATH` variable. However, without 
`7z` event when error is occured when downloading the circular archive, the script will be able to download all GCN circulars 
one-by-one, starting from #1. But is it desired to do so?

Just run `.\make_circular_draft.ps1` and enter source name in the prompt (or specify it with `-SourceName` option in the PowerShell).
Run `Get-Help .\make_circular_draft.ps1` to open the Help on script (this includes list of available options).

The real usage example is shown here:

```text
.\make_circular_draft.ps1 -SOURCE_NAME "GRB 241209B"
Probing downloading a new circular 38539 ...
The circular was downloaded successfully
No new GCN circulars yet
Searching for circulars on GRB 241209B ...

--
Found GCN
Subject: GRB 241209B: SVOM/ECLAIRs and GRM detection of a long burst
ID: 38478
Submitted by: SVOM_group <**>
Authors: Xie et. al

--
Found GCN
Subject: GRB 241209B: Swift ToO observations
ID: 38494
Submitted by: Phil Evans at U of Leicester <**>
Authors: Evans

--
Found GCN
Subject: GRB 241209B: BOOTES-5 optical upper limit
ID: 38499
Submitted by: **
Authors: Perez-Garcia et. al

--
Found GCN
Subject: GRB 241209B: SVOM/VT afterglow detection
ID: 38516
Submitted by: Chao Wu at NAOC <**>
Authors: Qiu et. al

--
Found GCN
Subject: GRB 241209B: Swift-XRT afterglow detection
ID: 38525
Submitted by: Phil Evans at U of Leicester <**>
Authors: Williams et. al

--
Found GCN
Subject: GRB 241209B: Swift/BAT-GUANO localization skymap of a burst
ID: 38528
Submitted by: Jimmy DeLaunay at Penn State <**>
Authors: DeLaunay et. al

--
Found GCN
Subject: GRB 241209B: GRBAlpha detection
ID: 38534
Submitted by: Marianna Dafčíková at Masaryk University <**>
Authors: Dafcikova et. al

--
Found GCN
Subject: Konus-Wind detection of GRB 241209B
ID: 38537
Submitted by: Anna Ridnaia at Ioffe Institute <**>
Authors: Ridnaia et. al

Results
--
Found 8 GCN circulars
GCN draft is in the gcn_draft_GRB 241209B.txt file.
Please, fill the fields that were not automatically filled (in <> bracketes).
```

The content of the generated GCN circular draft is as follows:

```text
GRB 241209B: <Telescope> optical observations

<Author 1 (Institute)> report on behalf of <team/collaboration>:

We performed optical observations of the field of GRB 241209B (Xie et. al, GCN 38478; Evans, GCN 38494; Perez-Garcia et. al, GCN 38499; Qiu et. al, GCN 38516; Williams et. al, GCN 38525; DeLaunay et. al, GCN 38528; Dafcikova et. al, GCN 38534; Ridnaia et. al, GCN 38537) in the <Filter> filter with <Telescope> of <Observatory> observatory. 
The observations began on <Date> <UT> UT, i.e. <Days> since trigger. 
The optical counterpart is <DetectedOrNot> in the stacked images. 
The preliminary photometry is given below:

Date       UT start  t-T0         Exp.    Filter   OT        Err.       UL(3sigma) Telescope
                     (mid, days)  (s)
<ISODate>  <HH:MM:SS> <days:.6f>  <n*exp> <Filter> <mag:.2f> <err:.2f>  <ul:.1f>   <Telescope>

The magnitudes were calibrated using nearby stars from <catalog> and are not corrected for the Galactic extinction towards the GRB 241209B.
```

Notice, there are fields `<days:.6f>` that should be update by hand or another software (e.g. using commands similar to `sed` or regex replacement in PowerShell). Here, after a column sign `:` a floating point precision is specified (like in default Python f-notation).
Also, it is important to grant rights to execute the script or if one does not want to do it, the content of this script can be copied into locally created `.ps1` file.
