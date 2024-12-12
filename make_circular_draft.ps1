Param (
    [string]$GCN_ARCHIVE_URL="https://gcn.nasa.gov/circulars/archive.json.tar.gz",
    [Parameter(Mandatory=$true)][string]$SOURCE_NAME
 )


$pos=0
if ($(Get-Content source_name.txt | Out-String).StartsWith($SOURCE_NAME)) {
    if ($(Test-Path -PathType Leaf first_gcn_pos.txt)) {
        $pos=[int]$(Get-Content first_gcn_pos.txt)
        Write-Debug "Source name is the same as already used. Starting position is $pos"
    }
} else { 
    $SOURCE_NAME > source_name.txt 
}


$curr_pwd=$(Get-Location)
try {
    mkdir circulars -Force | Out-Null
    cd circulars
    
    if (! $(Test-Path "archive.json.tar.gz" -PathType Leaf) ) {
        Write-Host "Downloading the GCN archive ..."
        Invoke-WebRequest $GCN_ARCHIVE_URL
        7z e archive.json.tar.gz
        7z e archive.json.tar
    }

    $maxGCNNum=[int]$(ls *json | Where-Object {$_ -match "\d+.json"} 
        | sort @{expression={[int]$_.Name.TrimEnd(".json")}}
        )[-1].Name.TrimEnd(".json")

    for (($i = $maxGCNNum + 1); $i -lt 99999999; $i++)
    {
        Write-Host "Probing downloading a new circular ${i} ..."
        try {
            Invoke-WebRequest "https://gcn.nasa.gov/circulars/${i}.json" -OutFile "${i}.json"
            Write-Host "The circular was downloaded successfully"
        } catch {
            Write-Debug "Error$_"
            Write-Host "No new GCN circulars yet"
            break
        }
    }
} finally {
    cd $curr_pwd
}

Write-Host "Searching for circulars on $SOURCE_NAME ..."

$fileNames=$(ls .\circulars\*json | Where-Object {$_ -match "\d+.json"}).FullName
$count=$fileNames.Length
if ( $($pos -ge $($count-1)) -or $($pos -lt 0) ) {
    Write-Debug "Postition $pos is out of bounds; starting from 0"
    $pos = 0
}

$writtenPos=False
$GCNcounter=0
$nFound=0
$CITE=""
foreach ($fn in $fileNames) {
    if ($GCNcounter -ge $pos) {
        $json = Get-Content $fn | Out-String | ConvertFrom-Json
        $subject = $json.subject
        if ($subject.Contains($SOURCE_NAME)) {
            Write-Host ""
            Write-Host "--"
            Write-Host "Found GCN"
            Write-Host "Subject: $subject"
            Write-Host "ID: $($json.circularID)"
            Write-Host "Submitted by: $($json.submitter)"

            $firstRow = $($([string]$json.body).TrimStart("`n") -Split "`n")[0].TrimEnd("`n").TrimStart("`n").TrimEnd(" ")

            # Author is the Fermi GBM team
            if ( $json.submitter.contains("Fermi GBM Team at MSFC/Fermi-GBM") ) {
                $authors="Fermi GBM team"
            # Author is the collaboration of LIGO, Virgo and KAGRA
            } elseif ( $firstRow.Contains("The LIGO Scientific Collaboration, the Virgo Collaboration, and the KAGRA Collaboration") ) {
                $authors="The LVK Collaboration"
            } elseif ( $($firstRow -match "(.+The)?[\w\d/\//\+\./`-`s,; ]+:?`s?" ) -and $($firstRow -notmatch "team: ") -and $($firstRow -notmatch "collaboration: ")) {
                # Authorship specified as this: M. A. Williams (PSU), J.P. Osborne (U. Leicester) report on behalf of:
                if ( $firstRow.Contains(",") ) {
                    $people=$firstRow.Split(", ")
                    if ( $people ) { 
                        $elementsOfName = $people[0].Split(" ")
                        # Parse name specified as this: Y. L. Qiu (NAOC)
                        if ( $elementsOfName[-1].StartsWith("(")) {
                            $authors=$elementsOfName[-2]
                        } else {
                            # Parse name specified as this: Y. L. Qiu
                            $authors=$elementsOfName[-1]
                        }
                    } else { $authors="" }
                    $authors="${authors} et. al"
                } else {
                    $elementsOfName=$firstRow.Split(" ")
                    for ($i=0; $i -lt 4; $i++) {
                        # Authorship specified as this: M. A. Williams (PSU) reports on behalf of:
                        if ( $elementsOfName[$i].StartsWith("(") ) {
                            if ( $i -gt 0 ) { $j=$($i-1); $authors=$elementsOfName[$j]; break }
                        }
                    }
                    # Authorship specified as this: M. A. Williams reports on behalf of:
                    if (! $authors ) { $authors=$elementsOfName[2] }
                    
                }
            } else {
                # Authorship is presented as SVOM/VT commissioning team: Y. L. Qiu, H. L. Li, L. P. Xin, ...
                if ( $firstRow -match "(.+team|.+collaboration): (.*?)" ) {
                    $experiment=$firstRow.Split(": ")[0]
                    $people=$firstRow.Split(": ")[1].Split(", ")
                    if ( $people ) { 
                        $elementsOfName = $people[0].Split(" ")
                        # Parse name specified as this: Y. L. Qiu (NAOC)
                        if ( $elementsOfName[-1].StartsWith("(") -or $elementsOfName[-1].EndsWith(")")) {
                            $authors=$elementsOfName[-2]
                        } else {
                            # Parse name specified as this: Y. L. Qiu (NAOC)
                            $authors=$elementsOfName[-1]
                        }
                        $authors="${authors} et. al"
                    } else {
                        $authors=$experiment
                    }
                } else {
                    $people=$firstRow.Split(", ")
                    if ( $people ) { 
                        $elementsOfName = $people[0].Split(" ")
                        # Parse name specified as this: Y. L. Qiu (NAOC)
                        if ( $elementsOfName[-1].StartsWith("(") -or $elementsOfName[-1].EndsWith(")")) {
                            $authors=$elementsOfName[-2]
                        } else {
                            # Parse name specified as this: Y. L. Qiu
                            $authors=$elementsOfName[-1]
                        }
                    } else { $authors="" }

                    $authors="${authors} et. al"
                }
            }
            
            Write-Host "Authors: $authors"  
            $CITE="${CITE}${authors}, GCN $($json.circularID); "
            if ($writtenPos) {
                Write-Debug "Found first GCN with $SOURCE_NAME in subject; saving its position $($GCNcounter-1)"
                $($GCNcounter-1) | Out-File first_gcn_pos.txt
                $writtenPos=True
            }
            $nFound+=1
        }
    }
    $GCNcounter += 1
}
$CITE=$CITE.TrimStart(";").TrimEnd("; ")

Write-Host "
Results
--"
if ($nFound) { 
    Write-Host "Found $nFound GCN circulars"
} else {
    Write-Warning "No GCN circulars found; probably you are first to publish about $SOURCE_NAME"
}


$body="
${SOURCE_NAME}: <Telescope> optical observations

<Author 1 (Institute)> report on behalf of <team/collaboration>:

We performed optical observations of the field of ${SOURCE_NAME} (${CITE}) in the <Filter> filter with <Telescope> of <Observatory> observatory. 
The observations began on <Date> <UT> UT, i.e. <Days> since trigger. 
The optical counterpart is <DetectedOrNot> in the stacked images. 
The preliminary photometry is given below:

Date       UT start  t-T0         Exp.    Filter   OT        Err.       UL(3sigma) Telescope
                     (mid, days)  (s)
<ISODate>  <HH:MM:SS> <days:.6f>  <n*exp> <Filter> <mag:.2f> <err:.2f>  <ul:.1f>   <Telescope>

The magnitudes were calibrated using nearby stars from <catalog> and are not corrected for the Galactic extinction towards the ${SOURCE_NAME}


" > "gcn_draft_${SOURCE_NAME}.txt"

Write-Host "GCN draft is in the gcn_draft_${SOURCE_NAME}.txt file. 
Please, fill the fields that were not automatically filled (in <> bracketes)."