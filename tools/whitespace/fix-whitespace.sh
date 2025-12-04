#!/usr/bin/env bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-i '')
esac

f=$1  # file

#sed "${SED_OPTIONS[@]}" '/^$/N;/\n$/D' "$f"                     # fix repeated blank lines
#sed "${SED_OPTIONS[@]}" 's/[[:space:]][[:space:]]*$//g' "$f"    # remove trailing white space

id='([0-9A-Za-z_]+)'  # java identifier
val='("[^"]*"|true|false|[0-9.]+)'  # java value
sed -E "${SED_OPTIONS[@]}" "s/@[[:space:]]*${id}[[:space:]]*\([[:space:]]*\)/@\1()/g" "$f"    # @Retryable()
sed -E "${SED_OPTIONS[@]}" "s/@[[:space:]]*${id}[[:space:]]*\([[:space:]]*${val}[[:space:]]*\)/@\1(\2)/g" "$f"    # @Retryable("sometimes")
sed -E "${SED_OPTIONS[@]}" "s/@[[:space:]]*${id}[[:space:]]*\([[:space:]]*${id}[[:space:]]*=[[:space:]]*${val}[[:space:]]*\)/@\1(\2 = \3)/g" "$f"    # @Retryable(attempts = "1")
sed -E "${SED_OPTIONS[@]}" "s/@[[:space:]]*${id}[[:space:]]*\([[:space:]]*${id}[[:space:]]*=[[:space:]]*${val}[[:space:]]*,[[:space:]]*${id}[[:space:]]*=[[:space:]]*${val}[[:space:]]*\)/@\1(\2 = \3, \4 = \5)/g" "$f"    # @Retryable(attempts = "1", delay = "100ms")

sed -E "${SED_OPTIONS[@]}" 's/\)[[:space:]]*\{$/) {/' "$f"                     # ) { -- at end of line
sed -E "${SED_OPTIONS[@]}" "s/${id}[[:space:]]*\{$/\1 {/" "$f"                     # Abcd { -- at end of line
#sed -E "${SED_OPTIONS[@]}" "s/${id}[[:space:]]*\)$/\1 )/" "$f"                     # Abcd ) -- at end of line

#sed -E "${SED_OPTIONS[@]}" 's/^([[:space:]]*[^"]*)[[:space:]][[:space:]]+([^"]*)$/\1 \2/' "$f"                     # repeated spaces
#sed -E "${SED_OPTIONS[@]}" 's/^([[:space:]]*[^"]*"[^"]*")[[:space:]][[:space:]]+([^"]*)$/\1 \2/' "$f"                     # repeated spaces
#sed -E "${SED_OPTIONS[@]}" 's/^([[:space:]]*[^"]*)[[:space:]][[:space:]]+([^"]*"[^"]*")$/\1 \2/' "$f"                     # repeated spaces


#        servers = {@Server(url = "http://contact-on-till:9999")}
#        servers = { @Server(url = "http://contact-on-till:9999") }

#class AuthorisationTokensAuthorisationTests
#{
# to:
#class AuthorisationTokensAuthorisationTests {

#   Map<String, Object> logContext = Map.of("traceId", traceId,
#                "userId", validateTokenResult.userId!=null ? validateTokenResult.userId: "N/A");
# to:
#      Map<String, Object> logContext = Map.of("traceId", traceId,
#                "userId", validateTokenResult.userId != null ? validateTokenResult.userId : "N/A");

#        if (paymentInfo != null && paymentInfo.getCashDispensed() != null && paymentInfo.getCashDispensed().getValue() != null){
# to:
#        if (paymentInfo != null && paymentInfo.getCashDispensed() != null && paymentInfo.getCashDispensed().getValue() != null) {

#    public boolean getIsInScheme() { return this.isInScheme; }
# to:
#    public boolean getIsInScheme() {
#        return this.isInScheme;
#    }

#                .withPromotionReward("Some description", "2","reason", "promotionId")
# to:
#                .withPromotionReward("Some description", "2", "reason", "promotionId")

#        QR("QR"),GS1_DATABAR_EXPANDED_STACKED("gs1DataBarExpandedStacked");
# to:
#        QR("QR"), GS1_DATABAR_EXPANDED_STACKED("gs1DataBarExpandedStacked");

#            this.name=name;
# to:
#            this.name = name;

#        if(storeLocation == null) return EmailReceiptAvailabilityLevel.NONE;
# to:
#        if (storeLocation == null) return EmailReceiptAvailabilityLevel.NONE;

