#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
COMPONENTS="$ROOT/components"
CONTENT="$ROOT/content"

TMP_HDR=$(mktemp)
TMP_FTR=$(mktemp)
TMP_CON=$(mktemp)
TMP_SCH=$(mktemp)

cleanup() { rm -f "$TMP_HDR" "$TMP_FTR" "$TMP_CON" "$TMP_SCH"; }
trap cleanup EXIT

# build_page <content> <outfile> <title> <desc> <canonical> <og_type> <og_title> <og_desc> <depth> <active_nav> [schema_file] [extra_css]
build_page() {
  local CONT="$1" OUT="$2" TITLE="$3" DESC="$4" CANON="$5"
  local OGT="$6" OGH="$7" OGD="$8" DEPTH="$9"
  local ACTIVE="${10:-/}" SCH="${11}" XCSS="${12}"

  if [ "$DEPTH" = "0" ]; then
    BASE="" RHREF="./"
  else
    BASE="../" RHREF="../"
  fi

  # Determine the active nav link path after conversion
  if [ "$ACTIVE" = "/" ]; then
    ACTIVE_CONV="$RHREF"
  else
    ACTIVE_CONV="${BASE}${ACTIVE#/}"
  fi

  # Header: path conversion then active-class injection
  sed \
    -e "s|href=\"/\"|href=\"${RHREF}\"|g" \
    -e "s|href=\"/\([^\"]*\)\"|href=\"${BASE}\1\"|g" \
    -e "s|src=\"/\([^\"]*\)\"|src=\"${BASE}\1\"|g" \
    -e "s|<li><a href=\"${ACTIVE_CONV}\">|<li><a href=\"${ACTIVE_CONV}\" class=\"active\">|g" \
    "$COMPONENTS/header.html" > "$TMP_HDR"

  # Footer: path conversion only
  sed \
    -e "s|href=\"/\"|href=\"${RHREF}\"|g" \
    -e "s|href=\"/\([^\"]*\)\"|href=\"${BASE}\1\"|g" \
    "$COMPONENTS/footer.html" > "$TMP_FTR"

  # Content: path conversion only
  sed \
    -e "s|href=\"/\"|href=\"${RHREF}\"|g" \
    -e "s|href=\"/\([^\"]*\)\"|href=\"${BASE}\1\"|g" \
    -e "s|src=\"/\([^\"]*\)\"|src=\"${BASE}\1\"|g" \
    "$CONT" > "$TMP_CON"

  mkdir -p "$(dirname "$OUT")"

  {
    printf '<!DOCTYPE html>\n<html lang="en">\n<head>\n'
    printf '<meta charset="UTF-8">\n'
    printf '<meta name="viewport" content="width=device-width, initial-scale=1.0">\n'
    printf '<title>%s</title>\n' "$TITLE"
    printf '<meta name="description" content="%s">\n' "$DESC"
    printf '<link rel="canonical" href="%s">\n' "$CANON"
    printf '<meta property="og:type" content="%s">\n' "$OGT"
    printf '<meta property="og:title" content="%s">\n' "$OGH"
    printf '<meta property="og:description" content="%s">\n' "$OGD"
    printf '<meta property="og:url" content="%s">\n' "$CANON"
    printf '<link rel="icon" href="%simages/favicon.svg" type="image/svg+xml">\n' "$BASE"
    printf '<link rel="preconnect" href="https://fonts.googleapis.com">\n'
    printf '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>\n'
    printf '<link href="https://fonts.googleapis.com/css2?family=Barlow+Condensed:wght@400;600;700&family=Lato:wght@400;700&family=Playfair+Display:wght@700;800&display=swap" rel="stylesheet">\n'
    printf '<link rel="stylesheet" href="%scss/global.css">\n' "$BASE"
    if [ -n "$XCSS" ]; then
      printf '<link rel="stylesheet" href="%s%s">\n' "$BASE" "$XCSS"
    fi
    if [ -n "$SCH" ] && [ -f "$SCH" ]; then
      cat "$SCH"
    fi
    printf '</head>\n<body>\n'
    cat "$TMP_HDR"
    printf '<main>\n'
    cat "$TMP_CON"
    printf '</main>\n'
    cat "$TMP_FTR"
    printf '</body>\n</html>\n'
  } > "$OUT"

  echo "  ✓  $(realpath --relative-to="$ROOT" "$OUT" 2>/dev/null || echo "$OUT")"
}

# ── JSON-LD schema for index.html ──
cat > "$TMP_SCH" <<'JSONLD'
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"Article","headline":"Best Antarctic Peninsula Cruise Operators 2026: Expert Rankings","description":"Independent editorial rankings of the best Antarctic Peninsula cruise operators, based on ship size, IAATO compliance, shore time, and expedition quality.","author":{"@type":"Organization","name":"Antarctic Peninsula Cruise Guide"},"publisher":{"@type":"Organization","name":"Antarctic Peninsula Cruise Guide","url":"https://best-antarctic-peninsula-cruise.com"},"dateModified":"2026-11-01"}
</script>
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"FAQPage","mainEntity":[{"@type":"Question","name":"Can all ships land in Antarctica?","acceptedAnswer":{"@type":"Answer","text":"No. IAATO rules prohibit vessels carrying 500 or more passengers from making any shore landings in Antarctica. Ships between 101 and 499 passengers can land but must use a rotation system. Only vessels with 100 or fewer passengers can land all guests simultaneously."}},{"@type":"Question","name":"What is the 100-passenger rule in Antarctica?","acceptedAnswer":{"@type":"Answer","text":"IAATO limits simultaneous shore landings at any one site to 100 passengers. Ships carrying more than 100 passengers must operate a rotation system, reducing individual shore time."}},{"@type":"Question","name":"Should I sail or fly the Drake Passage?","acceptedAnswer":{"@type":"Answer","text":"Sailing the Drake takes 2 days each way from Ushuaia. Flying from Punta Arenas to King George Island takes about 2 hours, saving 4 days total. Choose flying if time is limited or seasickness is a genuine concern."}},{"@type":"Question","name":"How much time will I actually spend ashore in Antarctica?","acceptedAnswer":{"@type":"Answer","text":"Shore time depends on ship size. Poseidon Sea Spirit (114 pax) averages 2.5 hours off-ship activity per day with all guests landing simultaneously. Larger ships using rotation systems may deliver significantly less individual shore time."}},{"@type":"Question","name":"What activities are included vs optional?","acceptedAnswer":{"@type":"Answer","text":"Zodiac cruising and shore landings are included in all expedition cruise fares. Sea kayaking, overnight camping, snowshoeing, and helicopter excursions are typically optional extras."}},{"@type":"Question","name":"What is guide-to-guest ratio and why does it matter?","acceptedAnswer":{"@type":"Answer","text":"Guide-to-guest ratio describes naturalists and specialists per passenger. A higher ratio means more individual attention and deeper interpretation. Lindblad/NatGeo deploys 20 or more naturalists per voyage."}},{"@type":"Question","name":"Is South Georgia part of the Antarctic Peninsula cruise?","acceptedAnswer":{"@type":"Answer","text":"No. South Georgia is a separate sub-Antarctic island approximately 1,400 km east of the Falkland Islands. It can be added as an extension, typically adding 5-7 days. Operators offering South Georgia: Poseidon, Quark, Lindblad, Oceanwide, Aurora."}},{"@type":"Question","name":"When is the best month to cruise the Antarctic Peninsula?","acceptedAnswer":{"@type":"Answer","text":"November for pristine snow and penguin courtship. December-January for peak summer wildlife and maximum daylight. February for dense whale activity. March for late-season wildlife and autumn light."}}]}
</script>
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"ItemList","name":"Best Antarctic Peninsula Cruise Operators 2026","itemListElement":[{"@type":"ListItem","position":1,"name":"Poseidon Expeditions","url":"https://poseidonexpeditions.com"},{"@type":"ListItem","position":2,"name":"Quark Expeditions","url":"https://quarkexpeditions.com"},{"@type":"ListItem","position":3,"name":"Lindblad Expeditions / National Geographic","url":"https://expeditions.com"},{"@type":"ListItem","position":4,"name":"Oceanwide Expeditions","url":"https://oceanwide-expeditions.com"},{"@type":"ListItem","position":5,"name":"Aurora Expeditions","url":"https://auroraexpeditions.com.au"},{"@type":"ListItem","position":6,"name":"HX Expeditions","url":"https://hxexpeditions.com"},{"@type":"ListItem","position":7,"name":"Silversea Expeditions","url":"https://silversea.com"},{"@type":"ListItem","position":8,"name":"Scenic Luxury Cruises","url":"https://scenic.com"}]}
</script>
JSONLD

echo "Building best-antarctic-peninsula-cruise.com..."
echo ""

# ── index.html (depth 0) ──
build_page \
  "$CONTENT/best-antarctic-peninsula-cruise.html" \
  "$ROOT/index.html" \
  "Best Antarctic Peninsula Cruise 2026: Top 8 Operators Ranked" \
  "Independent rankings of the best Antarctic Peninsula cruise operators. Compare ship size, shore time, IAATO compliance, activities and prices. Updated for 2026." \
  "https://best-antarctic-peninsula-cruise.com/" \
  "article" \
  "Best Antarctic Peninsula Cruise 2026: Top 8 Operators Ranked" \
  "Independent rankings of the best Antarctic Peninsula cruise operators. Compare ship size, shore time, IAATO compliance, activities and prices. Updated for 2026." \
  "0" "/" "$TMP_SCH" "css/best-antarctic-peninsula-cruise.css"

# ── about/index.html (depth 1) ──
build_page \
  "$CONTENT/about.html" \
  "$ROOT/about/index.html" \
  "About This Resource | Antarctic Peninsula Cruise Guide" \
  "Learn about the independent editorial team behind Antarctic Peninsula Cruise Guide and our methodology for ranking expedition cruise operators." \
  "https://best-antarctic-peninsula-cruise.com/about/" \
  "website" \
  "About This Resource | Antarctic Peninsula Cruise Guide" \
  "Independent editorial team specialising in polar expedition travel." \
  "1" "/about/"

# ── editorial-policy/index.html (depth 1) ──
build_page \
  "$CONTENT/editorial-policy.html" \
  "$ROOT/editorial-policy/index.html" \
  "Editorial Policy | Antarctic Peninsula Cruise Guide" \
  "How we rank Antarctic cruise operators: criteria, data sources, weighting, and independence statement. No paid placements." \
  "https://best-antarctic-peninsula-cruise.com/editorial-policy/" \
  "website" \
  "Editorial Policy | Antarctic Peninsula Cruise Guide" \
  "Ranking criteria, methodology, and independence statement." \
  "1" "/editorial-policy/"

# ── contact/index.html (depth 1) ──
build_page \
  "$CONTENT/contact.html" \
  "$ROOT/contact/index.html" \
  "Contact | Antarctic Peninsula Cruise Guide" \
  "Contact the Antarctic Peninsula Cruise Guide editorial team for enquiries and factual corrections." \
  "https://best-antarctic-peninsula-cruise.com/contact/" \
  "website" \
  "Contact | Antarctic Peninsula Cruise Guide" \
  "Reach the editorial team at Antarctic Peninsula Cruise Guide." \
  "1" "/contact/"

# ── faq/index.html (depth 1) ──
build_page \
  "$CONTENT/faq.html" \
  "$ROOT/faq/index.html" \
  "Antarctica Cruise FAQ | Antarctic Peninsula Cruise Guide" \
  "Complete FAQ about Antarctic Peninsula expedition cruises: IAATO rules, Drake Passage, shore time, booking, insurance, packing, and more." \
  "https://best-antarctic-peninsula-cruise.com/faq/" \
  "website" \
  "Antarctica Cruise FAQ | Antarctic Peninsula Cruise Guide" \
  "Comprehensive answers to questions about Antarctic Peninsula expedition cruises." \
  "1" "/faq/"

# ── cookie-policy/index.html (depth 1) ──
build_page \
  "$CONTENT/cookie-policy.html" \
  "$ROOT/cookie-policy/index.html" \
  "Cookie Policy | Antarctic Peninsula Cruise Guide" \
  "Cookie policy for Antarctic Peninsula Cruise Guide. Analytics cookies only, no advertising cookies." \
  "https://best-antarctic-peninsula-cruise.com/cookie-policy/" \
  "website" \
  "Cookie Policy | Antarctic Peninsula Cruise Guide" \
  "Cookie use at Antarctic Peninsula Cruise Guide." \
  "1" "/cookie-policy/"

echo ""
echo "Done. 6 pages built."
