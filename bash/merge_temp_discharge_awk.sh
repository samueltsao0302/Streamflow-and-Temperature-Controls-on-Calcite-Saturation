# Step 1. Find eligible sites (≥1000 discharge rows)

awk -F',' 'NR>1 {count[$1]++} END{for (s in count) if (count[s]>=1000) print s}' \

  discharge_daily_all.csv > eligible_sites.txt



# Step 2. Merge discharge + temp (left join on site_no+date), keep lon/lat from temp

awk -F',' '

# --- Pass 1: load eligible sites

FNR==NR { keep[$1]; next }



# --- Pass 2: load temp_daily.csv into arrays (lon, lat, temp)

FILENAME=="temp_daily.csv" {

  if (FNR==1) next

  key=$1 "," $7                 # site_no,date

  lon[$1]=$3; lat[$1]=$4        # dec_lon_va = col 3, dec_lat_va = col 4

  temp[key]=$8                  # value = col 8

  next

}



# --- Pass 3: stream discharge, keep only eligible sites, left join

FILENAME=="discharge_daily_all.csv" {

  if (FNR==1) { print "site_no,stream_date,lon,lat,discharge,temp"; next }

  site=$1; date=$2; discharge=$3

  if (site in keep) {

    key=site "," date

    t=(key in temp ? temp[key] : "")

    print site "," date "," lon[site] "," lat[site] "," discharge "," t

  }

}

' eligible_sites.txt temp_daily.csv discharge_daily_all.csv > discharge_temp_table.csv


