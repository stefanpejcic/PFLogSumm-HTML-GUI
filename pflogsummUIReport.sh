#!/usr/bin/env bash
# Debug option - should be disabled unless required
#set -x
#=====================================================================================================================
#   DESCRIPTION  Generating a stand alone web report for postix log files, 
#                Runs on all Linux platforms with postfix installed
#   AUTHOR       Riaan Pretorius <pretorius.riaan@gmail.com>
#   IDIOCRACY    yes.. i know.. bash??? WTF was i thinking?? Well it works, runs every 
#                where and it is portable
#
#   https://en.wikipedia.org/wiki/MIT_License
#
#   LICENSE
#   MIT License
#
#   Copyright (c) 2018 Riaan Pretorius
#
#   Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
#   and associated documentation files  (the "Software"), to deal in the Software without restriction, 
#   including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
#   and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, 
#   subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be included in all copies or substantial 
#   portions of the Software.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT 
#   NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
#   IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
#   WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION  WITH THE SOFTWARE 
#   OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#=====================================================================================================================

#CONFIG FILE LOCATION
PFSYSCONFDIR="/etc"

#Create Blank Config File if it does not exist
if [ ! -f ${PFSYSCONFDIR}/"pflogsumui.conf" ]
then
tee ${PFSYSCONFDIR}/"pflogsumui.conf" <<EOF
#PFLOGSUMUI CONFIG

##  Postfix Log Location
LOGFILELOCATION="/var/log/mail.log"

##  pflogsumm details
##  NOTE: DONT USE -d today - breaks the script
PFLOGSUMMOPTIONS=" --verbose_msg_detail --zero_fill "
PFLOGSUMMBIN="/usr/sbin/pflogsumm  "

##  HTML Output
HTMLOUTPUTDIR="/usr/local/admin/static/reports"
HTMLOUTPUT_INDEXDASHBOARD="/usr/local/admin/static/reports/reports.html"

EOF
echo "DEFAULT configuration file writen to ${PFSYSCONFDIR}/pflogsumui.conf, Please verify the paths before you continue"
exit 0
fi

# docker cp openadmin_mailserver:/usr/local/admin/static/reports/reports.html /usr/local/admin/templates/emails/reports.html
# docker cp openadmin_mailserver:/usr/local/admin/static/reports/data /usr/local/admin/templates/emails/data

#Load Config File
. ${PFSYSCONFDIR}/"pflogsumui.conf"


#Create the Cache Directory if it does not exist
if [ ! -d $HTMLOUTPUTDIR/data ]; then
  mkdir -p $HTMLOUTPUTDIR/data;
fi

#TOOLS
ACTIVEHOSTNAME=$(cat /proc/sys/kernel/hostname)
MOVEF="/usr/bin/mv -f "

#Temporal Values
REPORTDATE=$(date '+%Y-%m-%d %H:%M:%S')
CURRENTYEAR=$(date +'%Y')
CURRENTMONTH=$(date +'%b')
CURRENTDAY=$(printf "%d" $(date +"%e"))

$PFLOGSUMMBIN $PFLOGSUMMOPTIONS  -e $LOGFILELOCATION > /tmp/mailreport


#Extract Sections from PFLOGSUMM
sed -n '/^Grand Totals/,/^Per-Day/p;/^Per-Day/q' /tmp/mailreport | sed -e '1,4d' | sed -e :a -e '$d;N;2,3ba' -e 'P;D' | sed '/^$/d' > /tmp/GrandTotals
sed -n '/^Per-Day Traffic Summary/,/^Per-Hour/p;/^Per-Hour/q' /tmp/mailreport | sed -e '1,4d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D'  > /tmp/PerDayTrafficSummary
sed -n '/^Per-Hour Traffic Daily Average/,/^Host\//p;/^Host\//q' /tmp/mailreport | sed -e '1,4d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D'  > /tmp/PerHourTrafficDailyAverage
sed -n '/^Host\/Domain Summary\: Message Delivery/,/^Host\/Domain Summary\: Messages Received/p;/^Host\/Domain Summary\: Messages Received/q' /tmp/mailreport | sed -e '1,4d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D'  > /tmp/HostDomainSummaryMessageDelivery
sed -n '/^Host\/Domain Summary\: Messages Received/,/^Senders by message count/p;/^Senders by message count/q' /tmp/mailreport | sed -e '1,4d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D'  > /tmp/HostDomainSummaryMessagesReceived
sed -n '/^Senders by message count/,/^Recipients by message count/p;/^Recipients by message count/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/Sendersbymessagecount
sed -n '/^Recipients by message count/,/^Senders by message size/p;/^Senders by message size/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/Recipientsbymessagecount
sed -n '/^Senders by message size/,/^Recipients by message size/p;/^Recipients by message size/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/Sendersbymessagesize
sed -n '/^Recipients by message size/,/^Messages with no size data/p;/^Messages with no size data/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/Recipientsbymessagesize
sed -n '/^Messages with no size data/,/^message deferral detail/p;/^message deferral detail/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/Messageswithnosizedata
sed -n '/^message deferral detail/,/^message bounce detail (by relay)/p;/^message bounce detail (by relay)/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/messagedeferraldetail
sed -n '/^message bounce detail (by relay)/,/^message reject detail/p;/^message reject detail/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/messagebouncedetaibyrelay
sed -n '/^Warnings/,/^Fatal Errors/p;/^Fatal Errors/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/warnings

sed -n '/^Fatal Errors/,/^Master daemon messages/p;/^Master daemon messages/q' /tmp/mailreport | sed -e '1,2d' | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | sed '/^$/d' > /tmp/FatalErrors


#======================================================
# Extract Information into variables -> Grand Totals
#======================================================
ReceivedEmail=$(awk '$2=="received" && $1 ~ /^[0-9]+$/ {print $1}' /tmp/GrandTotals)
DeliveredEmail=$(awk '$2=="delivered" {print $1}'  /tmp/GrandTotals)
ForwardedEmail=$(awk '$2=="forwarded" {print $1}'  /tmp/GrandTotals)
DeferredEmailCount=$(awk '$2=="deferred" {print $1}'  /tmp/GrandTotals)
DeferredEmailDeferralsCount=$(awk '$2=="deferred" {print $3" "$4}'  /tmp/GrandTotals)
BouncedEmail=$(awk '$2=="bounced" {print $1}'  /tmp/GrandTotals)
RejectedEmailCount=$(awk '$2=="rejected" {print $1}'  /tmp/GrandTotals)
RejectedEmailPercentage=$(awk '$2=="rejected" {print $3}'  /tmp/GrandTotals)
RejectedWarningsEmail=$(sed 's/reject warnings/rejectwarnings/' /tmp/GrandTotals | awk '$2=="rejectwarnings" {print $1}')
HeldEmail=$(awk '$2=="held" {print $1}'  /tmp/GrandTotals)
DiscardedEmailCount=$(awk '$2=="discarded" {print $1}'  /tmp/GrandTotals)
DiscardedEmailPercentage=$(awk '$2=="discarded" {print $3}'  /tmp/GrandTotals)
BytesReceivedEmail=$(sed 's/bytes received/bytesreceived/' /tmp/GrandTotals | awk '$2=="bytesreceived" {print $1}'|sed 's/[^0-9]*//g' )
BytesDeliveredEmail=$(sed 's/bytes delivered/bytesdelivered/' /tmp/GrandTotals | awk '$2=="bytesdelivered" {print $1}'|sed 's/[^0-9]*//g')
SendersEmail=$(awk '$2=="senders" {print $1}'  /tmp/GrandTotals)
SendingHostsDomainsEmail=$(sed 's/sending hosts\/domains/sendinghostsdomains/' /tmp/GrandTotals | awk '$2=="sendinghostsdomains" {print $1}')
RecipientsEmail=$(awk '$2=="recipients" {print $1}'  /tmp/GrandTotals)
RecipientHostsDomainsEmail=$(sed 's/recipient hosts\/domains/recipienthostsdomains/' /tmp/GrandTotals | awk '$2=="recipienthostsdomains" {print $1}')


#======================================================
# Extract Information into variable -> Per-Day Traffic Summary
#======================================================
while IFS= read -r var
do
    PerDayTrafficSummaryTable=""
    PerDayTrafficSummaryTable+="<tr>"
    PerDayTrafficSummaryTable+=$(echo "$var" | awk '{print "<td>"$1" "$2" "$3"</td>""<td>"$4"</td>""<td>"$5"</td>""<td>"$6"</td>""<td>"$7"</td>""<td>"$8"</td>"}')
    PerDayTrafficSummaryTable+="</tr>"
    echo $PerDayTrafficSummaryTable >> /tmp/PerDayTrafficSummary_tmp
done < /tmp/PerDayTrafficSummary
$MOVEF  /tmp/PerDayTrafficSummary_tmp /tmp/PerDayTrafficSummary &> /dev/null

#======================================================
# Extract Information into variable -> Per-Hour Traffic Daily Average
#======================================================
while IFS= read -r var
do
    PerHourTrafficDailyAverageTable=""
    PerHourTrafficDailyAverageTable+="<tr>"
    PerHourTrafficDailyAverageTable+=$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>""<td>"$3"</td>""<td>"$4"</td>""<td>"$5"</td>""<td>"$6"</td>"}')
    PerHourTrafficDailyAverageTable+="</tr>"
    echo $PerHourTrafficDailyAverageTable >> /tmp/PerHourTrafficDailyAverage_tmp
done < /tmp/PerHourTrafficDailyAverage
$MOVEF /tmp/PerHourTrafficDailyAverage_tmp /tmp/PerHourTrafficDailyAverage &> /dev/null


#======================================================
# Extract Information into variable -> Per-Hour Traffic Daily Average
#======================================================
while IFS= read -r var
do
    HostDomainSummaryMessageDeliveryTable=""
    HostDomainSummaryMessageDeliveryTable+="<tr>"
    HostDomainSummaryMessageDeliveryTable+=$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>""<td>"$3"</td>""<td>"$4" "$5"</td>""<td>"$6" "$7"</td>""<td>"$8"</td>" }')
    HostDomainSummaryMessageDeliveryTable+="</tr>"
    echo $HostDomainSummaryMessageDeliveryTable >> /tmp/HostDomainSummaryMessageDelivery_tmp
done < /tmp/HostDomainSummaryMessageDelivery
$MOVEF /tmp/HostDomainSummaryMessageDelivery_tmp /tmp/HostDomainSummaryMessageDelivery &> /dev/null


#======================================================
# Extract Information into variable -> Host Domain Summary Messages Received
#======================================================
while IFS= read -r var
do
    HostDomainSummaryMessagesReceivedTable=""
    HostDomainSummaryMessagesReceivedTable+="<tr>"
    HostDomainSummaryMessagesReceivedTable+=$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>""<td>"$3"</td>"}')
    HostDomainSummaryMessagesReceivedTable+="</tr>"
    echo $HostDomainSummaryMessagesReceivedTable >> /tmp/HostDomainSummaryMessagesReceived_tmp
done < /tmp/HostDomainSummaryMessagesReceived
$MOVEF /tmp/HostDomainSummaryMessagesReceived_tmp /tmp/HostDomainSummaryMessagesReceived &> /dev/null


#======================================================
# Extract Information into variable -> Host Domain Summary Messages Received
#======================================================
while IFS= read -r var
do
    SendersbymessagecountTable=""
    SendersbymessagecountTable+="<tr>"
    SendersbymessagecountTable+=$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>"}')
    SendersbymessagecountTable+="</tr>"
    echo $SendersbymessagecountTable >> /tmp/Sendersbymessagecount_tmp
done < /tmp/Sendersbymessagecount
$MOVEF  /tmp/Sendersbymessagecount_tmp /tmp/Sendersbymessagecount &> /dev/null

#======================================================
# Extract Information into variable -> Recipients by message count
#======================================================
 while IFS= read -r var
do
    RecipientsbymessagecountTable=""
    RecipientsbymessagecountTable+="<tr>"
    RecipientsbymessagecountTable+=$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>"}')
    RecipientsbymessagecountTable+="</tr>"
    echo $RecipientsbymessagecountTable >> /tmp/Recipientsbymessagecount_tmp
done < /tmp/Recipientsbymessagecount
$MOVEF /tmp/Recipientsbymessagecount_tmp /tmp/Recipientsbymessagecount &> /dev/null


#======================================================
# Extract Information into variable -> Senders by message size
#======================================================
 while IFS= read -r var
do
    SendersbymessagesizeTable=""
    SendersbymessagesizeTable+="<tr>"
    SendersbymessagesizeTable+=$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>"}')
    SendersbymessagesizeTable+="</tr>"
    echo $SendersbymessagesizeTable >> /tmp/Sendersbymessagesize_tmp
done < /tmp/Sendersbymessagesize
$MOVEF /tmp/Sendersbymessagesize_tmp /tmp/Sendersbymessagesize &> /dev/null


#======================================================
# Extract Information into variable -> Recipients by messagesize Table
#======================================================
while IFS= read -r var
do
    RecipientsbymessagesizeTable=""
    RecipientsbymessagesizeTable+="<tr>"
    RecipientsbymessagesizeTable+=$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>"}')
    RecipientsbymessagesizeTable+="</tr>"
    echo $RecipientsbymessagesizeTable >> /tmp/Recipientsbymessagesize_tmp
done < /tmp/Recipientsbymessagesize
$MOVEF /tmp/Recipientsbymessagesize_tmp /tmp/Recipientsbymessagesize &> /dev/null

#======================================================
# Extract Information into variable -> Recipients by messagesize Table
#======================================================
while IFS= read -r var
do
    MessageswithnosizedataTable=""
    MessageswithnosizedataTable+="<tr>"
    MessageswithnosizedataTable+=$(echo "$var" | awk '{print "<td>"$1"</td>""<td>"$2"</td>"}')
    MessageswithnosizedataTable+="</tr>"
    echo $MessageswithnosizedataTable >> /tmp/Messageswithnosizedata_tmp
    echo $MessageswithnosizedataTable
done < /tmp/Messageswithnosizedata
$MOVEF  /tmp/Messageswithnosizedata_tmp /tmp/Messageswithnosizedata  &> /dev/null

#======================================================
# Single PAGE INDEX HTML TEMPLATE
# Using embedded HTML makes the script highly portable
# SED search and replace tags to fill the content
#======================================================

cat > $HTMLOUTPUT_INDEXDASHBOARD << 'HTMLOUTPUTINDEXDASHBOARD'
{% extends 'base.html' %}

{% block content %}

<!-- Page Header -->
<div class="border-b border-gray-200 bg-gray-50 p-4 dark:border-gray-800 dark:bg-gray-950 sm:p-6 lg:p-8">
    <header>
        <div class="flex flex-col gap-2 text-center sm:flex-row sm:items-center sm:justify-between sm:text-start">
            <div class="grow">
                <h1 class="mb-1 text-xl font-bold">Summary Reports</h1>
                <h2 class="text-sm font-medium text-slate-500"></h2>
            </div>
            <div class="group sm:text-right items-center justify-center gap-2 rounded-sm px-2 sm:justify-end sm:bg-transparent sm:px-0">
              <div>Last Update: <b>##REPORTDATE##</b></div>
              <div>Server: <b>##ACTIVEHOSTNAME##</b></div>
            </div>
        </div>
    </header>
</div>


<!-- Reports -->
<div class="container mx-auto px-4 py-6 space-y-8">
    {% for month in [
        'January', 'February', 'March', 'April',
        'May', 'June', 'July', 'August',
        'September', 'October', 'November', 'December'
    ] %}
        <div class="border bg-white dark:bg-[#090E1A] border-gray-200 dark:border-gray-900 rounded-lg shadow p-6" x-data="{ open: false }">
            <div class="flex justify-between items-center">
                <div>
                    <h3 class="text-xl font-semibold">{{ month }}</h3>
                    <p class="text-sm text-gray-500 mt-1">Report Count:
                        <span class="ml-1 inline-block bg-blue-100 text-blue-800 text-xs px-2 py-1 rounded-full">
                            ##{{ month }}Count##
                        </span>
                    </p>
                </div>
                <button @click="open = !open" class="text-blue-600 hover:underline text-sm">
                    <span x-text="open ? 'Hide Reports' : 'View Reports'"></span>
                </button>
            </div>

            <div x-show="open" x-collapse class="mt-4">
                <div class="list-group list-group-flush flex gap-2 {{ month }}List">
                    <!-- Dynamic Item List -->
                </div>
            </div>
        </div>
    {% endfor %}
</div>

<script>
document.addEventListener('DOMContentLoaded', () => {
    const months = [
        'January', 'February', 'March', 'April',
        'May', 'June', 'July', 'August',
        'September', 'October', 'November', 'December'
    ];

    months.forEach(month => {
        const className = `.${month}List`;
        const element = document.querySelector(className);

        // Skip if the element doesn't exist
        if (!element) return;

        // Clear current content
        element.innerHTML = '';

        const file = `/emails/data/${month.toLowerCase().slice(0, 3)}_rpt.html?rnd=` + Math.random();

        fetch(file)
            .then(res => {
                if (!res.ok) {
                    // If 404 or other error, skip silently
                    console.warn(`Could not load report for ${month}: ${res.status}`);
                    return '';
                }
                return res.text();
            })
            .then(html => {
                if (html) element.innerHTML = html;
            })
            .catch(err => {
                console.error(`Error fetching ${month} report:`, err);
            });
    });
});
</script>

{% endblock %}

HTMLOUTPUTINDEXDASHBOARD



#======================================================
# Single PAGE REPORT HTML TEMPLATE
# Using embedded HTML makes the script highly portable
# SED search and replace tags to fill the content
#======================================================
#2018-Nov-17.html

cat > "$HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html" << 'HTMLREPORTDASHBOARD'
{% extends 'base.html' %}

{% block content %}

<!-- Page Header -->
<div class="border-b border-gray-200 bg-gray-50 p-4 dark:border-gray-800 dark:bg-gray-950 sm:p-6 lg:p-8">
    <header>
        <div class="flex flex-col gap-2 text-center sm:flex-row sm:items-center sm:justify-between sm:text-start">
            <div class="grow">
                <h1 class="mb-1 text-xl font-bold">Summary Reports</h1>
                <h2 class="text-sm font-medium text-slate-500"></h2>
            </div>
            <div class="group sm:text-right items-center justify-center gap-2 rounded-sm px-2 sm:justify-end sm:bg-transparent sm:px-0">
              <div>Report Date: <b>##REPORTDATE##</b></div>
              <div>Hostname: <b>##ACTIVEHOSTNAME##</b></div>
            </div>
        </div>
    </header>
</div>

<!-- Icons -->
<script src="https://unpkg.com/feather-icons/dist/feather.min.js"></script>

<!-- Graphs -->
<script src="https://code.highcharts.com/highcharts.js"></script>
<script src="https://code.highcharts.com/modules/data.js"></script>
<script src="https://code.highcharts.com/modules/exporting.js"></script>
<script src="https://code.highcharts.com/modules/export-data.js"></script>

<div class="container mx-auto py-6">

    <!-- Quick Stats -->
    <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4 mb-6">

        <div class="border bg-white dark:bg-[#090E1A] border-gray-200 dark:border-gray-900 shadow rounded p-4 text-center">
            <div class="text-2xl font-bold">##ReceivedEmail##</div>
            <div class="text-sm mt-1">Received Email</div>
        </div>
        <div class="border bg-white dark:bg-[#090E1A] border-gray-200 dark:border-gray-900 shadow rounded p-4 text-center">
            <div class="text-2xl font-bold">##DeliveredEmail##</div>
            <div class="text-sm mt-1">Delivered Mail</div>
        </div>
        <div class="border bg-white dark:bg-[#090E1A] border-gray-200 dark:border-gray-900 shadow rounded p-4 text-center">
            <div class="text-2xl font-bold">##ForwardedEmail##</div>
            <div class="text-sm mt-1">Forwarded Mail</div>
        </div>
        <div class="border bg-white dark:bg-[#090E1A] border-gray-200 dark:border-gray-900 shadow rounded p-4 text-center">
            <div class="text-2xl font-bold">##DeferredEmailCount##</div>
            <div class="text-sm mt-1">Deferred ##DeferredEmailDeferralsCount##</div>
        </div>
        <div class="border bg-white dark:bg-[#090E1A] border-gray-200 dark:border-gray-900 shadow rounded p-4 text-center">
            <div class="text-2xl font-bold">##BouncedEmail##</div>
            <div class="text-sm mt-1">Bounced Mail</div>
        </div>
        <div class="border bg-white dark:bg-[#090E1A] border-gray-200 dark:border-gray-900 shadow rounded p-4 text-center">
            <div class="text-2xl font-bold">##RejectedWarningsEmail##</div>
            <div class="text-sm mt-1">Reject Warnings ##RejectedEmailPercentage##</div>
        </div>
        <div class="border bg-white dark:bg-[#090E1A] border-gray-200 dark:border-gray-900 shadow rounded p-4 text-center">
            <div class="text-2xl font-bold">##RejectedEmailCount##</div>
            <div class="text-sm mt-1">Rejected Mail ##RejectedEmailPercentage##</div>
        </div>
        <div class="border bg-white dark:bg-[#090E1A] border-gray-200 dark:border-gray-900 shadow rounded p-4 text-center">
            <div class="text-2xl font-bold">##HeldEmail##</div>
            <div class="text-sm mt-1">Held Mail</div>
        </div>
        <div class="border bg-white dark:bg-[#090E1A] border-gray-200 dark:border-gray-900 shadow rounded p-4 text-center">
            <div class="text-2xl font-bold">##DiscardedEmailCount##</div>
            <div class="text-sm mt-1">Discarded Mail ##DiscardedEmailPercentage##</div>
        </div>
        <div class="border bg-white dark:bg-[#090E1A] border-gray-200 dark:border-gray-900 shadow rounded p-4 text-center">
            <div class="text-2xl font-bold">##BytesReceivedEmail##</div>
            <div class="text-sm mt-1">Bytes Received</div>
        </div>
        <div class="border bg-white dark:bg-[#090E1A] border-gray-200 dark:border-gray-900 shadow rounded p-4 text-center">
            <div class="text-2xl font-bold">##BytesDeliveredEmail##</div>
            <div class="text-sm mt-1">Bytes Delivered</div>
        </div>
        <div class="border bg-white dark:bg-[#090E1A] border-gray-200 dark:border-gray-900 shadow rounded p-4 text-center">
            <div class="text-2xl font-bold">##SendersEmail##</div>
            <div class="text-sm mt-1">Mail Senders</div>
        </div>
        <div class="border bg-white dark:bg-[#090E1A] border-gray-200 dark:border-gray-900 shadow rounded p-4 text-center">
            <div class="text-2xl font-bold">##SendingHostsDomainsEmail##</div>
            <div class="text-sm mt-1">Sending Hosts/Domains</div>
        </div>
        <div class="border bg-white dark:bg-[#090E1A] border-gray-200 dark:border-gray-900 shadow rounded p-4 text-center">
            <div class="text-2xl font-bold">##RecipientsEmail##</div>
            <div class="text-sm mt-1">Mail Recipients</div>
        </div>

    </div>

    <!-- Hidden tables for Highcharts - MUST be real DOM tables, not Alpine-injected -->
    <table id="PerDayTrafficSummaryTable" style="display:none">
        <thead>
            <tr><th>Date</th><th>Received</th><th>Delivered</th><th>Deferred</th><th>Bounced</th><th>Rejected</th></tr>
        </thead>
        <tbody>
        ##PerDayTrafficSummaryTableHC##
        </tbody>
    </table>
    
    <table id="PerHourTrafficDailyAverageTable" style="display:none">
        <thead>
            <tr><th>Time</th><th>Received</th><th>Delivered</th><th>Deferred</th><th>Bounced</th><th>Rejected</th></tr>
        </thead>
        <tbody>
        ##PerHourTrafficDailyAverageTableHC##
        </tbody>
    </table>

    <!-- Graphs -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 my-6">
        <div class="border bg-white dark:bg-[#090E1A] border-gray-200 dark:border-gray-900 p-4 rounded shadow">
            <div id="PerDayTrafficSummaryTableGraph" style="height:24rem; width:100%;"></div>
        </div>
        <div class="border bg-white dark:bg-[#090E1A] border-gray-200 dark:border-gray-900 p-4 rounded shadow">
            <div id="PerHourTrafficDailyAverageTableGraph" style="height:24rem; width:100%;"></div>
        </div>
    </div>

    <!-- Hidden data stores for collapsible table sections -->
    <!-- These are plain HTML divs - bash replaces the ##placeholders## safely here, outside Alpine/JS context -->
    <div id="data-PerDayTrafficSummary" style="display:none">
    ##PerDayTrafficSummaryTable##
    </div>
    <div id="data-PerHourTrafficDailyAverage" style="display:none">
    ##PerHourTrafficDailyAverageTable##
    </div>
    <div id="data-HostDomainSummaryMessagesReceived" style="display:none">
    ##HostDomainSummaryMessagesReceived##
    </div>
    <div id="data-SendersbyMessageSize" style="display:none">
    ##SendersbyMessageSize##
    </div>
    <div id="data-Sendersbymessagecount" style="display:none">
    ##Sendersbymessagecount##
    </div>
    <div id="data-RecipientsbyMessageCount" style="display:none">
    ##RecipientsbyMessageCount##
    </div>
    <div id="data-HostDomainSummaryMessageDelivery" style="display:none">
    ##HostDomainSummaryMessageDelivery##
    </div>
    <div id="data-Recipientsbymessagesize" style="display:none">
    ##Recipientsbymessagesize##
    </div>
    <div id="data-Messageswithnosizedata" style="display:none">
    ##Messageswithnosizedata##
    </div>
    <div id="data-MessageDeferralDetail" style="display:none">
    ##MessageDeferralDetail##
    </div>
    <div id="data-MessageBounceDetailbyrelay" style="display:none">
    ##MessageBounceDetailbyrelay##
    </div>
    <div id="data-MailWarnings" style="display:none">
    ##MailWarnings##
    </div>
    <div id="data-MailFatalErrors" style="display:none">
    ##MailFatalErrors##
    </div>

    <!-- Collapsible Sections - NO HTML content inside Alpine array, only IDs and metadata -->
    <div class="space-y-4" id="collapsible-sections"></div>

</div>

<script>
feather.replace();

// Highcharts graphs - reads from real DOM tables above
Highcharts.chart('PerDayTrafficSummaryTableGraph', {
    data: { table: 'PerDayTrafficSummaryTable' },
    chart: { type: 'line' },
    title: { text: 'Per-Day Traffic Summary' },
    yAxis: { allowDecimals: false, title: { text: 'Units' } },
    plotOptions: { line: { dataLabels: { enabled: true }, enableMouseTracking: true } }
});

Highcharts.chart('PerHourTrafficDailyAverageTableGraph', {
    data: { table: 'PerHourTrafficDailyAverageTable' },
    chart: { type: 'line' },
    title: { text: 'Per-Hour Traffic Daily Average' },
    yAxis: { allowDecimals: false, title: { text: 'Units' } },
    plotOptions: { line: { dataLabels: { enabled: true }, enableMouseTracking: true } }
});

// Collapsible sections - built in plain JS, no Alpine, no HTML in arrays
var sections = [
    { id: 'PerDayTrafficSummary',              title: 'Per-Day Traffic Summary',                    headers: ['Date','Received','Delivered','Deferred','Bounced','Rejected'], pre: false },
    { id: 'PerHourTrafficDailyAverage',        title: 'Per-Hour Traffic Daily Average',              headers: ['Time','Received','Delivered','Deferred','Bounced','Rejected'], pre: false },
    { id: 'HostDomainSummaryMessagesReceived', title: 'Host/Domain Summary: Messages Received',      headers: ['Message Count','Bytes','Host/Domain'],                         pre: false },
    { id: 'SendersbyMessageSize',              title: 'Senders by Message Size',                    headers: ['Size','Sender'],                                               pre: false },
    { id: 'Sendersbymessagecount',             title: 'Senders by Message Count',                   headers: ['Message Count','Sender'],                                      pre: false },
    { id: 'RecipientsbyMessageCount',          title: 'Recipients by Message Count',                headers: ['Message Count','Recipient'],                                   pre: false },
    { id: 'HostDomainSummaryMessageDelivery',  title: 'Host/Domain Summary: Message Delivery',      headers: ['Sent Count','Bytes','Defers','Avg Daily','Max Daily','Host/Domain'], pre: false },
    { id: 'Recipientsbymessagesize',           title: 'Recipients by Message Size',                 headers: ['Size','Recipient'],                                            pre: false },
    { id: 'Messageswithnosizedata',            title: 'Messages with No Size Data',                 headers: ['Queue ID','Email Address'],                                    pre: false },
    { id: 'MessageDeferralDetail',             title: 'Message Deferral Detail',                    headers: [],                                                              pre: true  },
    { id: 'MessageBounceDetailbyrelay',        title: 'Message Bounce Detail (By Relay)',           headers: [],                                                              pre: true  },
    { id: 'MailWarnings',                      title: 'Mail Warnings',                              headers: [],                                                              pre: true  },
    { id: 'MailFatalErrors',                   title: 'Mail Fatal Errors',                          headers: [],                                                              pre: true  }
];

var container = document.getElementById('collapsible-sections');

sections.forEach(function(section) {
    var dataEl = document.getElementById('data-' + section.id);
    var tbody = dataEl ? dataEl.querySelector('tbody') : null;
    var content = tbody ? tbody.innerHTML : (dataEl ? dataEl.innerHTML : '');

    // Build inner content
    var innerHtml = '';
    if (section.pre) {
        innerHtml = '<pre class="whitespace-pre-wrap overflow-auto max-h-96 text-sm">' + content + '</pre>';
    } else {
        var headerCells = section.headers.map(function(h) {
            return '<th class="px-4 py-2">' + h + '</th>';
        }).join('');
        innerHtml =
            '<div class="overflow-x-auto">' +
              '<table class="min-w-full text-sm text-left text-gray-700">' +
                '<thead class="bg-gray-100 font-semibold"><tr>' + headerCells + '</tr></thead>' +
                '<tbody>' + content + '</tbody>' +
              '</table>' +
            '</div>';
    }

    // Build collapsible wrapper
    var wrapper = document.createElement('div');
    wrapper.className = 'border bg-white dark:bg-[#090E1A] border-gray-200 dark:border-gray-900 p-4 rounded shadow';
    wrapper.innerHTML =
        '<h3 class="cursor-pointer text-lg font-semibold border-b pb-2 flex justify-between items-center" onclick="toggleSection(this)">' +
            '<span>' + section.title + '</span>' +
            '<span class="text-sm text-blue-600">Show</span>' +
        '</h3>' +
        '<div class="section-body mt-2" style="display:none">' + innerHtml + '</div>';

    container.appendChild(wrapper);
});

function toggleSection(header) {
    var body = header.nextElementSibling;
    var label = header.querySelector('span:last-child');
    if (body.style.display === 'none') {
        body.style.display = 'block';
        label.textContent = 'Hide';
    } else {
        body.style.display = 'none';
        label.textContent = 'Show';
    }
}
</script>

{% endblock %}
HTMLREPORTDASHBOARD


#======================================================
# Replace Placeholders with values - GrandTotals
#======================================================
sed -i "s/##REPORTDATE##/$REPORTDATE/g" $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html
sed -i "s/##ACTIVEHOSTNAME##/$ACTIVEHOSTNAME/g" $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html
sed -i "s/##ReceivedEmail##/$ReceivedEmail/g" $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html
sed -i "s/##DeliveredEmail##/$DeliveredEmail/g" $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html
sed -i "s/##ForwardedEmail##/$ForwardedEmail/g" $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html
sed -i "s/##DeferredEmailCount##/$DeferredEmailCount/g" $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html
sed -i "s/##DeferredEmailDeferralsCount##/$DeferredEmailDeferralsCount/g" $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html
sed -i "s/##BouncedEmail##/$BouncedEmail/g" $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html
sed -i "s/##RejectedEmailCount##/$RejectedEmailCount/g" $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html
sed -i "s/##RejectedEmailPercentage##/$RejectedEmailPercentage/g" $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html
sed -i "s/##RejectedWarningsEmail##/$RejectedWarningsEmail/g" $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html
sed -i "s/##HeldEmail##/$HeldEmail/g" $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html
sed -i "s/##DiscardedEmailCount##/$DiscardedEmailCount/g" $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html
sed -i "s/##DiscardedEmailPercentage##/$DiscardedEmailPercentage/g" $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html
sed -i "s/##BytesReceivedEmail##/$BytesReceivedEmail/g" $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html
sed -i "s/##BytesDeliveredEmail##/$BytesDeliveredEmail/g" $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html
sed -i "s/##SendersEmail##/$SendersEmail/g" $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html
sed -i "s/##SendingHostsDomainsEmail##/$SendingHostsDomainsEmail/g" $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html
sed -i "s/##RecipientsEmail##/$RecipientsEmail/g" $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html
sed -i "s/##RecipientHostsDomainsEmail##/$RecipientHostsDomainsEmail/g" $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html

#======================================================
# Replace Placeholders with values - Table PerDayTrafficSummaryTable
#======================================================
sed -i '/##PerDayTrafficSummaryTable##/ {
r /tmp/PerDayTrafficSummary
d
}' $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html 


#======================================================
# Replace Placeholders with values - Table PerHourTrafficDailyAverageTable
#======================================================
sed -i '/##PerHourTrafficDailyAverageTable##/ {
r /tmp/PerHourTrafficDailyAverage
d
}' $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html 


#======================================================
# Replace Placeholders with values - Table HostDomainSummaryMessageDelivery
#======================================================
sed -i '/##HostDomainSummaryMessageDelivery##/ {
r /tmp/HostDomainSummaryMessageDelivery
d
}' $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html 

#======================================================
# Replace Placeholders with values - Table HostDomainSummaryMessagesReceived
#======================================================
sed -i '/##HostDomainSummaryMessagesReceived##/ {
r /tmp/HostDomainSummaryMessagesReceived
d
}' $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html 

#======================================================
# Replace Placeholders with values - Table Sendersbymessagecount
#======================================================
sed -i '/##Sendersbymessagecount##/ {
r /tmp/Sendersbymessagecount
d
}' $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html 

#======================================================
# Replace Placeholders with values - Table RecipientsbyMessageCount
#======================================================
sed -i '/##RecipientsbyMessageCount##/ {
r /tmp/Recipientsbymessagecount
d
}' $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html 

#======================================================
# Replace Placeholders with values - Table SendersbyMessageSize
#======================================================
sed -i '/##SendersbyMessageSize##/ {
r /tmp/Sendersbymessagesize
d
}' $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html 

#======================================================
# Replace Placeholders with values - Table Recipientsbymessagesize
#======================================================
sed -i '/##Recipientsbymessagesize##/ {
r /tmp/Recipientsbymessagesize
d
}' $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html 

#======================================================
# Replace Placeholders with values - Table Messageswithnosizedata
#======================================================
sed -i '/##Messageswithnosizedata##/ {
r /tmp/Messageswithnosizedata
d
}' $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html 


#======================================================
# Replace Placeholders with values -  MessageDeferralDetail
#======================================================
sed -i '/##MessageDeferralDetail##/ {
r /tmp/messagedeferraldetail
d
}' $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html 

#======================================================
# Replace Placeholders with values -  MessageBounceDetailbyrelay
#======================================================
sed -i '/##MessageBounceDetailbyrelay##/ {
r /tmp/messagebouncedetaibyrelay
d
}' $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html 


#======================================================
# Replace Placeholders with values - warnings
#======================================================
sed -i '/##MailWarnings##/ {
r /tmp/warnings
d
}' $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html 


#======================================================
# Replace Placeholders with values - FatalErrors
#======================================================
sed -i '/##MailFatalErrors##/ {
r /tmp/FatalErrors
d
}' $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html 



# HC
sed -i '/##PerDayTrafficSummaryTableHC##/ {
r /tmp/PerDayTrafficSummary
d
}' $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html

sed -i '/##PerHourTrafficDailyAverageTableHC##/ {
r /tmp/PerHourTrafficDailyAverage
d
}' $HTMLOUTPUTDIR/data/$CURRENTYEAR-$CURRENTMONTH-$CURRENTDAY.html


#======================================================
# Count Existing Reports - For Dashboard Display
#======================================================
JanRPTCount=$(find $HTMLOUTPUTDIR/data  -maxdepth 1 -type f -name $CURRENTYEAR-Jan*.html | wc -l)
FebRPTCount=$(find $HTMLOUTPUTDIR/data  -maxdepth 1 -type f -name $CURRENTYEAR-Feb*.html | wc -l)
MarRPTCount=$(find $HTMLOUTPUTDIR/data  -maxdepth 1 -type f -name $CURRENTYEAR-Mar*.html | wc -l)
AprRPTCount=$(find $HTMLOUTPUTDIR/data  -maxdepth 1 -type f -name $CURRENTYEAR-Apr*.html | wc -l)
MayRPTCount=$(find $HTMLOUTPUTDIR/data  -maxdepth 1 -type f -name $CURRENTYEAR-May*.html | wc -l)
JunRPTCount=$(find $HTMLOUTPUTDIR/data  -maxdepth 1 -type f -name $CURRENTYEAR-Jun*.html | wc -l)
JulRPTCount=$(find $HTMLOUTPUTDIR/data  -maxdepth 1 -type f -name $CURRENTYEAR-Jul*.html | wc -l)
AugRPTCount=$(find $HTMLOUTPUTDIR/data  -maxdepth 1 -type f -name $CURRENTYEAR-Aug*.html | wc -l)
SepRPTCount=$(find $HTMLOUTPUTDIR/data  -maxdepth 1 -type f -name $CURRENTYEAR-Sep*.html | wc -l)
OctRPTCount=$(find $HTMLOUTPUTDIR/data  -maxdepth 1 -type f -name $CURRENTYEAR-Oct*.html | wc -l)
NovRPTCount=$(find $HTMLOUTPUTDIR/data  -maxdepth 1 -type f -name $CURRENTYEAR-Nov*.html | wc -l)
DecRPTCount=$(find $HTMLOUTPUTDIR/data  -maxdepth 1 -type f -name $CURRENTYEAR-Dec*.html | wc -l)


#======================================================
# Replace Report Totals for Report - Index
#======================================================
sed -i "s/##JanuaryCount##/$JanRPTCount/g" $HTMLOUTPUT_INDEXDASHBOARD
sed -i "s/##FebruaryCount##/$FebRPTCount/g" $HTMLOUTPUT_INDEXDASHBOARD
sed -i "s/##MarchCount##/$MarRPTCount/g" $HTMLOUTPUT_INDEXDASHBOARD
sed -i "s/##AprilCount##/$AprRPTCount/g" $HTMLOUTPUT_INDEXDASHBOARD
sed -i "s/##MayCount##/$MayRPTCount/g" $HTMLOUTPUT_INDEXDASHBOARD
sed -i "s/##JuneCount##/$JunRPTCount/g" $HTMLOUTPUT_INDEXDASHBOARD
sed -i "s/##JulyCount##/$JulRPTCount/g" $HTMLOUTPUT_INDEXDASHBOARD
sed -i "s/##AugustCount##/$AugRPTCount/g" $HTMLOUTPUT_INDEXDASHBOARD
sed -i "s/##SeptemberCount##/$SepRPTCount/g" $HTMLOUTPUT_INDEXDASHBOARD
sed -i "s/##OctoberCount##/$OctRPTCount/g" $HTMLOUTPUT_INDEXDASHBOARD
sed -i "s/##NovemberCount##/$NovRPTCount/g" $HTMLOUTPUT_INDEXDASHBOARD
sed -i "s/##DecemberCount##/$DecRPTCount/g" $HTMLOUTPUT_INDEXDASHBOARD

sed -i "s/##REPORTDATE##/$REPORTDATE/g" $HTMLOUTPUT_INDEXDASHBOARD
sed -i "s/##ACTIVEHOSTNAME##/$ACTIVEHOSTNAME/g" $HTMLOUTPUT_INDEXDASHBOARD


#======================================================
# Update Clickable Index Files (imported dynamicly)
#======================================================

#Delete Exisitng File Indexs
rm -fr $HTMLOUTPUTDIR/data/*_rpt.html

#Get List of report files
for filename in $HTMLOUTPUTDIR/data/*.html; do
    filenameWithExtOnly="${filename##*/}"
    filenameWithoutExtension="${filenameWithExtOnly%.*}"
    filenameDate="${filenameWithoutExtension##*-}"
 
    case $filenameWithExtOnly in
        *Jan* )  
        echo "<a href=\"/emails/data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameDate</a>" >> $HTMLOUTPUTDIR/data/jan_rpt.html
        ;;

        *Feb* )  
        echo "<a href=\"/emails/data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameDate</a>" >> $HTMLOUTPUTDIR/data/feb_rpt.html
        ;;

        *Mar* )  
        echo "<a href=\"/emails/data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameDate</a>" >> $HTMLOUTPUTDIR/data/mar_rpt.html
        ;;

        *Apr* )  
        echo "<a href=\"/emails/data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameDate</a>" >> $HTMLOUTPUTDIR/data/apr_rpt.html
        ;;

        *May* )  
        echo "<a href=\"/emails/data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameDate</a>" >> $HTMLOUTPUTDIR/data/may_rpt.html
        ;;

        *Jun* )  
        echo "<a href=\"/emails/data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameDate</a>" >> $HTMLOUTPUTDIR/data/jun_rpt.html
        ;;                                        

        *Jul* )  
        echo "<a href=\"/emails/data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameDate</a>" >> $HTMLOUTPUTDIR/data/jul_rpt.html
        ;;

        *Aug* )  
        echo "<a href=\"/emails/data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameDate</a>" >> $HTMLOUTPUTDIR/data/aug_rpt.html
        ;;

        *Sep* )  
        echo "<a href=\"/emails/data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameDate</a>" >> $HTMLOUTPUTDIR/data/sep_rpt.html
        ;;

        *Oct* )  
        echo "<a href=\"/emails/data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameDate</a>" >> $HTMLOUTPUTDIR/data/oct_rpt.html
        ;;        

        *Nov* )  
        echo "<a href=\"/emails/data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameDate</a>" >> $HTMLOUTPUTDIR/data/nov_rpt.html
        ;;      

        *Dec* )  
        echo "<a href=\"/emails/data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameDate</a>" >> $HTMLOUTPUTDIR/data/dec_rpt.html
        ;;          
    esac  
done


#======================================================
# Clean UP
#======================================================
