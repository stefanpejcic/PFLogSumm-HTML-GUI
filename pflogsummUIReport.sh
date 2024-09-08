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
ReceivedEmail=$(awk '$2=="received" {print $1}'  /tmp/GrandTotals)
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

<div>
    {% with messages = get_flashed_messages() %}
        {% if messages %}
            {% for message in messages %}
                <div class="alert alert-warning alert-dismissible" role="alert">
                    {{ message }}
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            {% endfor %}
        {% endif %}
    {% endwith %}
</div>


<!-- Page header -->
<div class="page-header mt-0 d-print-none">
    <div class="container-xl">
        <div class="row g-2 align-items-center">
            <div class="col">
                <!-- Page pre-title -->
                <div class="page-pretitle">
                    Emails
                </div>
                <h2 class="page-title">
                    Generated Reports
                </h2>
            </div>
            <!-- Page title actions -->
            <div class="col-auto ms-auto mt-0 d-print-none">
                <div class="">
                Last Update: <b>##REPORTDATE##</b>
                <br>
                Server: <b>##ACTIVEHOSTNAME##</b>
                </div>
            </div>
        </div>
    </div>
</div>

    <div class="page-body">

        <div class="row">

            <div class="col-sm">

                <!-- January Start-->
                <div class="card flex-md-row mb-4">
                    <div class="card-body d-flex flex-column align-items-start">
                        <h5><strong class="d-inline-block mb-2 text-primary">January</strong></h5>
                        <h6>Report Count <span class="badge badge-primary">##JanuaryCount##</span></h6>
                        <div class="spacer10"></div>
                        <a data-bs-toggle="collapse" href="#JanuaryCard" aria-expanded="true" class="d-block"> View
                            Reports </a>
                        <div id="JanuaryCard" class="collapse hide">
                            <div class="card-body ">
                                <div class="list-group list-group-flush JanuaryList ">
                                    <!-- Dynamic Item List-->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- January End -->

            </div>

            <div class="col-sm">

                <!-- February Start-->
                <div class="card flex-md-row mb-4">
                    <div class="card-body d-flex flex-column align-items-start">
                        <h5><strong class="d-inline-block mb-2 text-primary">February</strong></h5>
                        <h6>Report Count <span class="badge badge-primary">##FebruaryCount##</span></h6>
                        <div class="spacer10"></div>
                        <a data-bs-toggle="collapse" href="#FebruaryCard" aria-expanded="true" class="d-block"> View
                            Reports </a>
                        <div id="FebruaryCard" class="collapse hide">
                            <div class="card-body ">
                                <div class="list-group list-group-flush FebruaryList ">
                                    <!-- Dynamic Item List-->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- February End -->

            </div>

            <div class="col-sm">

                <!-- March Start-->
                <div class="card flex-md-row mb-4">
                    <div class="card-body d-flex flex-column align-items-start">
                        <h5><strong class="d-inline-block mb-2 text-primary">March</strong></h5>
                        <h6>Report Count <span class="badge badge-primary">##MarchCount##</span></h6>
                        <div class="spacer10"></div>
                        <a data-bs-toggle="collapse" href="#MarchCard" aria-expanded="true" class="d-block"> View
                            Reports </a>
                        <div id="MarchCard" class="collapse hide">
                            <div class="card-body ">
                                <div class="list-group list-group-flush MarchList ">
                                    <!-- Dynamic Item List-->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- March End -->

            </div>

            <div class="col-sm">

                <!-- April Start-->
                <div class="card flex-md-row mb-4">
                    <div class="card-body d-flex flex-column align-items-start">
                        <h5><strong class="d-inline-block mb-2 text-primary">April</strong></h5>
                        <h6>Report Count <span class="badge badge-primary">##AprilCount##</span></h6>
                        <div class="spacer10"></div>
                        <a data-bs-toggle="collapse" href="#AprilCard" aria-expanded="true" class="d-block"> View
                            Reports </a>
                        <div id="AprilCard" class="collapse hide">
                            <div class="card-body ">
                                <div class="list-group list-group-flush AprilList ">
                                    <!-- Dynamic Item List-->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- April End -->

            </div>


        </div>

        <br>

        <div class="row">

            <div class="col-sm">

                <!-- May Start-->
                <div class="card flex-md-row mb-4">
                    <div class="card-body d-flex flex-column align-items-start">
                        <h5><strong class="d-inline-block mb-2 text-primary">May</strong></h5>
                        <h6>Report Count <span class="badge badge-primary">##MayCount##</span></h6>
                        <div class="spacer10"></div>
                        <a data-bs-toggle="collapse" href="#MayCard" aria-expanded="true" class="d-block"> View
                            Reports </a>
                        <div id="MayCard" class="collapse hide">
                            <div class="card-body ">
                                <div class="list-group list-group-flush MayList ">
                                    <!-- Dynamic Item List-->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- May End -->

            </div>

            <div class="col-sm">

                <!-- June Start-->
                <div class="card flex-md-row mb-4">
                    <div class="card-body d-flex flex-column align-items-start">
                        <h5><strong class="d-inline-block mb-2 text-primary">June</strong></h5>
                        <h6>Report Count <span class="badge badge-primary">##JuneCount##</span></h6>
                        <div class="spacer10"></div>
                        <a data-bs-toggle="collapse" href="#JuneCard" aria-expanded="true" class="d-block"> View
                            Reports </a>
                        <div id="JuneCard" class="collapse hide">
                            <div class="card-body ">
                                <div class="list-group list-group-flush JuneList ">
                                    <!-- Dynamic Item List-->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- June End -->

            </div>

            <div class="col-sm">

                <!-- July Start-->
                <div class="card flex-md-row mb-4">
                    <div class="card-body d-flex flex-column align-items-start">
                        <h5><strong class="d-inline-block mb-2 text-primary">July</strong></h5>
                        <h6>Report Count <span class="badge badge-primary">##JulyCount##</span></h6>
                        <div class="spacer10"></div>
                        <a data-bs-toggle="collapse" href="#JulyCard" aria-expanded="true" class="d-block"> View
                            Reports </a>
                        <div id="JulyCard" class="collapse hide">
                            <div class="card-body ">
                                <div class="list-group list-group-flush JulyList ">
                                    <!-- Dynamic Item List-->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- July End -->

            </div>

            <div class="col-sm">

                <!-- August Start-->
                <div class="card flex-md-row mb-4">
                    <div class="card-body d-flex flex-column align-items-start">
                        <h5><strong class="d-inline-block mb-2 text-primary">August</strong></h5>
                        <h6>Report Count <span class="badge badge-primary">##AugustCount##</span></h6>
                        <div class="spacer10"></div>
                        <a data-bs-toggle="collapse" href="#AugustCard" aria-expanded="true" class="d-block"> View
                            Reports </a>
                        <div id="AugustCard" class="collapse hide">
                            <div class="card-body ">
                                <div class="list-group list-group-flush AugustList ">
                                    <!-- Dynamic Item List-->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- August End -->

            </div>

        </div>

        <br>

        <div class="row">

            <div class="col-sm">

                <!-- September Start-->
                <div class="card flex-md-row mb-4">
                    <div class="card-body d-flex flex-column align-items-start">
                        <h5><strong class="d-inline-block mb-2 text-primary">September</strong></h5>
                        <h6>Report Count <span class="badge badge-primary">##SeptemberCount##</span></h6>
                        <div class="spacer10"></div>
                        <a data-bs-toggle="collapse" href="#SeptemberCard" aria-expanded="true" class="d-block"> View
                            Reports </a>
                        <div id="SeptemberCard" class="collapse hide">
                            <div class="card-body ">
                                <div class="list-group list-group-flush SeptemberList ">
                                    <!-- Dynamic Item List-->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- September End -->

            </div>

            <div class="col-sm">

                <!-- October Start-->
                <div class="card flex-md-row mb-4">
                    <div class="card-body d-flex flex-column align-items-start">
                        <h5><strong class="d-inline-block mb-2 text-primary">October</strong></h5>
                        <h6>Report Count <span class="badge badge-primary">##OctoberCount##</span></h6>
                        <div class="spacer10"></div>
                        <a data-bs-toggle="collapse" href="#OctoberCard" aria-expanded="true" class="d-block"> View
                            Reports </a>
                        <div id="OctoberCard" class="collapse hide">
                            <div class="card-body ">
                                <div class="list-group list-group-flush OctoberList ">
                                    <!-- Dynamic Item List-->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- October End -->

            </div>

            <div class="col-sm">

                <!-- November Start-->
                <div class="card flex-md-row mb-4">
                    <div class="card-body d-flex flex-column align-items-start">
                        <h5><strong class="d-inline-block mb-2 text-primary">November</strong></h5>
                        <h6>Report Count <span class="badge badge-primary">##NovemberCount##</span></h6>
                        <div class="spacer10"></div>
                        <a data-bs-toggle="collapse" href="#NovemberCard" aria-expanded="true" class="d-block"> View
                            Reports </a>
                        <div id="NovemberCard" class="collapse hide">
                            <div class="card-body ">
                                <div class="list-group list-group-flush NovemberList ">
                                    <!-- Dynamic Item List-->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- November End -->

            </div>

            <div class="col-sm">

                <!-- December Start-->
                <div class="card flex-md-row mb-4">
                    <div class="card-body d-flex flex-column align-items-start">
                        <h5><strong class="d-inline-block mb-2 text-primary">December</strong></h5>
                        <h6>Report Count <span class="badge badge-primary">##DecemberCount##</span></h6>
                        <div class="spacer10"></div>
                        <a data-bs-toggle="collapse" href="#DecemberCard" aria-expanded="true" class="d-block"> View
                            Reports </a>
                        <div id="DecemberCard" class="collapse hide">
                            <div class="card-body ">
                                <div class="list-group list-group-flush DecemberList ">
                                    <!-- Dynamic Item List-->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- December End -->

            </div>

        </div>

    </div>

<script>
    $(document).ready(function () {
        $('.JanuaryList').load("/emails/data/jan_rpt.html?rnd=" + Math.random());
        $('.FebruaryList').load("/emails/data/feb_rpt.html?rnd=" + Math.random());
        $('.MarchList').load("/emails/data/mar_rpt.html?rnd=" + Math.random());
        $('.AprilList').load("/emails/data/apr_rpt.html?rnd=" + Math.random());
        $('.MayList').load("/emails/data/may_rpt.html?rnd=" + Math.random());
        $('.JuneList').load("/emails/data/jun_rpt.html?rnd=" + Math.random());
        $('.JulyList').load("/emails/data/jul_rpt.html?rnd=" + Math.random());
        $('.AugustList').load("/emails/data/aug_rpt.html?rnd=" + Math.random());
        $('.SeptemberList').load("/emails/data/sep_rpt.html?rnd=" + Math.random());
        $('.OctoberList').load("/emails/data/oct_rpt.html?rnd=" + Math.random());
        $('.NovemberList').load("/emails/data/nov_rpt.html?rnd=" + Math.random());
        $('.DecemberList').load("/emails/data/dec_rpt.html?rnd=" + Math.random());
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
<!doctype html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <meta name="description" content="Postfix Report">
    <meta name="author" content="">
    <link rel="icon" href="http://www.postfix.org/favicon.ico">

    <title>Postfix PFLOGSUMM Report</title>

    <!-- Bootstrap core CSS -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.1.3/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.4.2/css/all.css" integrity="sha384-/rXc/GQVaYpyDdyxK+ecHPVYJSN9bmVFBvjA/9eOB+pb3F2w2N6fc5qB9Ew5yIns"
        crossorigin="anonymous">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.15.0/themes/prism.css">



    <style>
        body {
            padding-top: 5rem;
        }

        footer {
            background-color: #eee;
            padding: 25px;
        }

        .spacer15 {
            height: 15px;
        }
    </style>

</head>

<body>

    <nav class="navbar navbar-expand-md navbar-dark bg-dark fixed-top">
        <a class="navbar-brand" href="../">Postfix Report</a>
    </nav>


    <!-- Server/Report INFO -->
    <div class="container rounded shadow-sm  p-3 my-3 text-white-50 bg-dark ">
        <div class="row">
            <div class="card-body">
                <div class="row mb-4">
                    <div class="col-sm-12">
                        <div> <strong>Hostname</strong> </div>
                        <h6 class="mb-3">##ACTIVEHOSTNAME##</h6>
                        <div> <strong>Report Date</strong> </div>
                        <div>##REPORTDATE##</div>
                        <div class="spacer15"></div>
                        <div>This report exposes email addresses of end users / Please password protect this resource</div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <!-- Server/Report INFO -->

    <br>

    <!-- Quick Status Blocks -->
    <div class="container rounded shadow-sm  text-white bg-dark ">
        <!-- Row -->
        <div class="row counter-box text-center">
            <!-- column  -->
            <div class="col-lg-2 col-6">
                <div class="">
                    <h5 class="font-mute text-mute"><span class="counter font-weight-bold">##ReceivedEmail##</span></h5>
                    <span style="font-size: 0.85em;">Received Email</span>
                </div>
            </div>
            <!-- column  -->
            <!-- column  -->
            <div class="col-lg-2 col-6">
                <div class="">
                    <h5 class="font-mute text-mute"><span class="counter font-weight-bold">##DeliveredEmail##</span></h5>
                    <span style="font-size: 0.85em;">Delivered Mail</span>
                </div>
            </div>
            <!-- column  -->
            <!-- column  -->
            <div class="col-lg-2 col-6">
                <div class="">
                    <h5 class="font-mute text-mute"><span class="counter font-weight-bold">##ForwardedEmail##</span></h5>
                    <span style="font-size: 0.85em;">Forwarded Mail</span>
                </div>
            </div>
            <!-- column  -->
            <!-- column  -->
            <div class="col-lg-2 col-6">
                <div class="">
                    <h5 class="font-mute text-mute"><span class="counter font-weight-bold">##DeferredEmailCount##</span></h5>
                    <span style="font-size: 0.85em;">Deferred ##DeferredEmailDeferralsCount##</span>
                </div>
            </div>
            <!-- column  -->
            <!-- column  -->
            <div class="col-lg-2 col-6">
                <div class="">
                    <h5 class="font-mute text-mute"><span class="counter font-weight-bold">##BouncedEmail##</span></h5>
                    <span style="font-size: 0.85em;">Bounced Mail</span>
                </div>
            </div>
            <!-- column  -->
            <!-- column  -->
            <div class="col-lg-2 col-6">
                <div class="">
                    <h5 class="font-mute text-mute"><span class="counter font-weight-bold">##RejectedWarningsEmail##</span></h5>
                    <span style="font-size: 0.85em;">Rejected Warning ##RejectedEmailPercentage##</span>
                </div>
            </div>
            <!-- column  -->
        </div>

        <div class="spacer15"></div>

        <!-- Row -->
        <div class="row counter-box text-center">
            <!-- column  -->
            <div class="col-lg-2 col-6">
                <div class="">
                    <h5 class="font-mute text-mute"><span class="counter font-weight-bold">##RejectedEmailCount##</span></h5>
                    <span style="font-size: 0.85em;">Rejected Mail ##RejectedEmailPercentage##</span>
                </div>
            </div>
            <!-- column  -->
            <!-- column  -->
            <div class="col-lg-2 col-6">
                <div class="">
                    <h5 class="font-mute text-mute"><span class="counter font-weight-bold">##HeldEmail##</span></h5>
                    <span style="font-size: 0.85em;">Held Mail</span>
                </div>
            </div>
            <!-- column  -->
            <!-- column  -->
            <div class="col-lg-2 col-6">
                <div class="">
                    <h5 class="font-mute text-mute"><span class="counter font-weight-bold">##DiscardedEmailCount##</span></h5>
                    <span style="font-size: 0.85em;">Discarded Mail ##DiscardedEmailPercentage##</span>
                </div>
            </div>
            <!-- column  -->
            <!-- column  -->
            <div class="col-lg-2 col-6">
                <div class="">
                    <h5 class="font-mute text-mute"><span class="counter font-weight-bold">##BytesReceivedEmail##</span></h5>
                    <span style="font-size: 0.85em;">Bytes Received</span>
                </div>
            </div>
            <!-- column  -->
            <!-- column  -->
            <div class="col-lg-2 col-6">
                <div class="">
                    <h5 class="font-mute text-mute"><span class="counter font-weight-bold">##BytesDeliveredEmail##</span></h5>
                    <span style="font-size: 0.85em;">Bytes Delivered</span>
                </div>
            </div>
            <!-- column  -->
            <!-- column  -->
            <div class="col-lg-2 col-6">
                <div class="">
                    <h5 class="font-mute text-mute"><span class="counter font-weight-bold">##SendersEmail##</span></h5>
                    <span style="font-size: 0.85em;">Mail Senders</span>
                </div>
            </div>
            <!-- column  -->
        </div>

        <div class="spacer15"></div>

        <!-- Row -->
        <div class="row counter-box text-center">
            <!-- column  -->
            <div class="col-lg-2 col-6">
                <div class="">
                    <h5 class="font-mute text-mute"><span class="counter font-weight-bold">##SendingHostsDomainsEmail##</span></h5>
                    <span style="font-size: 0.85em;">Sending Hosts/Domains</span>
                </div>
            </div>
            <!-- column  -->
            <!-- column  -->
            <div class="col-lg-2 col-6">
                <div class="">
                    <h5 class="font-mute text-mute"><span class="counter font-weight-bold">##RecipientsEmail##</span></h5>
                    <span style="font-size: 0.85em;">Mail Recipients</span>
                </div>
            </div>
            <!-- column  -->

        </div>
        <!-- Quick Status Blocks -->
    </div>



    <div class="container rounded shadow-sm  p-3 my-3 ">

        <div class="my-3 p-3 bg-white  rounded shadow-sm">
            <h6 class="border-bottom border-gray pb-2 mb-0">Graphs</h6>

            <div class="container">
                <div class="row">
                    <div class="col-md-12">
                        <div id="PerDayTrafficSummaryTableGraph" style="width: auto; height: 400px; "></div>
                    </div>
                </div>
            </div>

            <div class="container">
                <div class="row">
                    <div class="col-md-12">
                        <div id="PerHourTrafficDailyAverageTableGraph" style="width: auto; height: 400px;"></div>
                    </div>
                </div>
            </div>
        </div>


        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <a data-bs-toggle="collapse" href="#PerDayTrafficSummary" role="button" aria-expanded="false" aria-controls="PerDayTrafficSummary">
                <h6 class="border-bottom border-gray pb-2 mb-0">Per-Day Traffic Summary</h6>
            </a>
            <div class="container collapse" id="PerDayTrafficSummary">
                <div class="row">
                    <div class="col-md-12">
                        <div class="table-responsive" id="PerDayTrafficSummaryTable">
                            <table class="table-responsive table-striped table-sm">
                                <thead>
                                    <tr>
                                        <th scope="col">Date</th>
                                        <th scope="col">Received</th>
                                        <th scope="col">Delivered</th>
                                        <th scope="col">Deferred</th>
                                        <th scope="col">Bounced</th>
                                        <th scope="col">Rejected</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ##PerDayTrafficSummaryTable##
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <a data-bs-toggle="collapse" href="#PerHourTrafficDailyAverage" role="button" aria-expanded="false"
                aria-controls="PerHourTrafficDailyAverage">
                <h6 class="border-bottom border-gray pb-2 mb-0">Per-Hour Traffic Daily Average</h6>
            </a>
            <div class="container collapse" id="PerHourTrafficDailyAverage">
                <div class="row">
                    <div class="col-md-12">
                        <div class="table-responsive" id="PerHourTrafficDailyAverageTable">
                            <table class="table-responsive table-striped table-sm">
                                <thead>
                                    <tr>
                                        <th scope="col">Time</th>
                                        <th scope="col">Received</th>
                                        <th scope="col">Delivered</th>
                                        <th scope="col">Deferred</th>
                                        <th scope="col">Bounced</th>
                                        <th scope="col">Rejected</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ##PerHourTrafficDailyAverageTable##
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>


        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <a data-bs-toggle="collapse" href="#HostDomainSummaryMessagesReceived" role="button" aria-expanded="false"
                aria-controls="HostDomainSummaryMessagesReceived">
                <h6 class="border-bottom border-gray pb-2 mb-0">Host/Domain Summary: Messages Received</h6>
            </a>
            <div class="container collapse" id="HostDomainSummaryMessagesReceived">
                <div class="row">
                    <div class="col-md-12">
                        <div class="table-responsive">
                            <table class="table-responsive table-striped table-sm">
                                <thead>
                                    <tr>
                                        <th scope="col">Message Count</th>
                                        <th scope="col">Bytes</th>
                                        <th scope="col">Host/Domain</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ##HostDomainSummaryMessagesReceived##
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <a data-bs-toggle="collapse" href="#SendersbyMessageSize" role="button" aria-expanded="false" aria-controls="SendersbyMessageSize">
                <h6 class="border-bottom border-gray pb-2 mb-0">Senders by Message Size</h6>
            </a>
            <div class="container collapse" id="SendersbyMessageSize">
                <div class="row">
                    <div class="col-md-12">
                        <div class="table-responsive">
                            <table class="table-responsive table-striped table-sm">
                                <thead>
                                    <tr>
                                        <th scope="col">Size</th>
                                        <th scope="col">Sender</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ##SendersbyMessageSize##
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <a data-bs-toggle="collapse" href="#SendersbyMessageCount" role="button" aria-expanded="false" aria-controls="SendersbyMessageCount">
                <h6 class="border-bottom border-gray pb-2 mb-0">Senders by Message Count</h6>
            </a>
            <div class="container collapse" id="SendersbyMessageCount">
                <div class="row">
                    <div class="col-md-12">
                        <div class="table-responsive">
                            <table class="table-responsive table-striped table-sm">
                                <thead>
                                    <tr>
                                        <th scope="col">Message Count</th>
                                        <th scope="col">Sender</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ##Sendersbymessagecount##
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <a data-bs-toggle="collapse" href="#RecipientsbyMessageCount" role="button" aria-expanded="false"
                aria-controls="RecipientsbyMessageCount">
                <h6 class="border-bottom border-gray pb-2 mb-0">Recipients by Message Count</h6>
            </a>
            <div class="container collapse" id="RecipientsbyMessageCount">
                <div class="row">
                    <div class="col-md-12">
                        <div class="table-responsive">
                            <table class="table-responsive table-striped table-sm">
                                <thead>
                                    <tr>
                                        <th scope="col">Message Count</th>
                                        <th scope="col">Recipient</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ##RecipientsbyMessageCount##
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>


        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <a data-bs-toggle="collapse" href="#HostDomainSummaryMessageDelivery" role="button" aria-expanded="false"
                aria-controls="HostDomainSummaryMessageDelivery">
                <h6 class="border-bottom border-gray pb-2 mb-0">Host/Domain Summary: Message Delivery</h6>
            </a>
            <div class="container collapse" id="HostDomainSummaryMessageDelivery">
                <div class="row">
                    <div class="col-md-12">
                        <div class="table-responsive">
                            <table class="table-responsive table-striped table-sm">
                                <thead>
                                    <tr>
                                        <th scope="col">Sent Count</th>
                                        <th scope="col">Bytes</th>
                                        <th scope="col">Defers</th>
                                        <th scope="col">Average Daily</th>
                                        <th scope="col">Maximum Daily</th>
                                        <th scope="col">Host/Domain</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ##HostDomainSummaryMessageDelivery##
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>


        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <a data-bs-toggle="collapse" href="#Recipientsbymessagesize" role="button" aria-expanded="false" aria-controls="Recipientsbymessagesize">
                <h6 class="border-bottom border-gray pb-2 mb-0">Recipients by message size</h6>
            </a>
            <div class="container collapse" id="Recipientsbymessagesize">
                <div class="row">
                    <div class="col-md-12">
                        <div class="table-responsive">
                            <table class="table-responsive table-striped table-sm">
                                <thead>
                                    <tr>
                                        <th scope="col">Size</th>
                                        <th scope="col">Recipient</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ##Recipientsbymessagesize##
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <a data-bs-toggle="collapse" href="#Messageswithnosizedata" role="button" aria-expanded="false" aria-controls="Messageswithnosizedata">
                <h6 class="border-bottom border-gray pb-2 mb-0">Messages with no size data</h6>
            </a>
            <div class="container collapse" id="Messageswithnosizedata">
                <div class="row">
                    <div class="col-md-12">
                        <div class="table-responsive">
                            <table class="table-responsive table-striped table-sm">
                                <thead>
                                    <tr>
                                        <th scope="col">Queue ID</th>
                                        <th scope="col">Email Address</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ##Messageswithnosizedata##
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>


        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <a data-bs-toggle="collapse" href="#MessageDeferralDetail" role="button" aria-expanded="false" aria-controls="MessageDeferralDetail">
                <h6 class="border-bottom border-gray pb-2 mb-0">Message Deferral Detail</h6>
            </a>
            <div class="container collapse" id="MessageDeferralDetail">
                <div class="row">
                    <div class="col-md-12">
                        <br>
                        <div class="pre-scrollable" style="max-height: 40vh; ">
                            <pre>
                                    ##MessageDeferralDetail##
                        </pre>
                        </div>
                        <br>
                    </div>
                </div>
            </div>
        </div>



        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <a data-bs-toggle="collapse" href="#MessageBounceDetailbyrelay" role="button" aria-expanded="false"
                aria-controls="MessageBounceDetailbyrelay">
                <h6 class="border-bottom border-gray pb-2 mb-0">Message Bounce Detail (By Relay)</h6>
            </a>
            <div class="container collapse" id="MessageBounceDetailbyrelay">
                <div class="row">
                    <div class="col-md-12">
                        <br>
                        <div class="pre-scrollable" style="max-height: 40vh; ">
                            <pre>
                                        ##MessageBounceDetailbyrelay##
                            </pre>
                        </div>
                        <br>
                    </div>
                </div>
            </div>
        </div>

        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <a data-bs-toggle="collapse" href="#MailWarnings" role="button" aria-expanded="false" aria-controls="MailWarnings">
                <h6 class="border-bottom border-gray pb-2 mb-0">Mail Warnings</h6>
            </a>
            <div class="container collapse" id="MailWarnings">
                <div class="row">
                    <div class="col-md-12">
                        <br>
                        <div class="pre-scrollable" style="max-height: 40vh; ">
                            <pre>
                                            ##MailWarnings##
                                </pre>
                        </div>
                        <br>
                    </div>
                </div>
            </div>
        </div>

        <div class="my-3 p-3 bg-white rounded shadow-sm">
            <a data-bs-toggle="collapse" href="#MailFatalErrors" role="button" aria-expanded="false" aria-controls="MailFatalErrors">
                <h6 class="border-bottom border-gray pb-2 mb-0">Mail Fatal Errors</h6>
            </a>
            <div class="container collapse" id="MailFatalErrors">
                <div class="row">
                    <div class="col-md-12">
                        <br>
                        <div class="pre-scrollable" style="max-height: 40vh; ">
                            <pre>
                                        ##MailFatalErrors##
                                    </pre>
                        </div>
                        <br>
                    </div>
                </div>
            </div>
        </div>
    </div>





    <br>


    <!-- Footer -->
    <footer class="container-fluid bg-dark text-center text-white-50">
        <div class="copyrights" style="margin-top:5px;">
            <p>&copy;
                <script>new Date().getFullYear() > 2010 && document.write(new Date().getFullYear());</script>
                <br>
                <span>Powered by <a href="https://github.com/KTamas/pflogsumm">PFLOGSUMM</a> </span> /
                <span><a href="https://github.com/RiaanPretoriusSA/PFLogSumm-HTML-GUI">PFLOGSUMM HTML UI Report</a>
                </span>
            </p>
        </div>
    </footer>




    <!-- Bootstrap core JavaScript
    ================================================== -->
    <!-- Placed at the end of the document so the pages load faster -->
    <script src="https://code.jquery.com/jquery-3.2.1.slim.min.js" integrity="sha384-KJ3o2DKtIkvYIK3UENzmM7KCkRr/rE9/Qpg6aAZGJwFDMVNA/GpGFF93hXpG5KkN"
        crossorigin="anonymous"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.12.9/umd/popper.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.1.3/js/bootstrap.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/waypoints/4.0.1/jquery.waypoints.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/Counter-Up/1.0.0/jquery.counterup.js"></script>


    <!-- Icons -->
    <script src="https://unpkg.com/feather-icons/dist/feather.min.js"></script>
    <script>
        feather.replace()
    </script>

    <!-- Graphs -->
    <script src="https://code.highcharts.com/highcharts.js"></script>
    <script src="https://code.highcharts.com/modules/data.js"></script>
    <script src="https://code.highcharts.com/modules/exporting.js"></script>
    <script src="https://code.highcharts.com/modules/export-data.js"></script>

    <!-- Code Highlight-->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.15.0/prism.min.js"></script>




    <script>

        Highcharts.chart('PerDayTrafficSummaryTableGraph', {
            data: {
                table: 'PerDayTrafficSummaryTable'
            },
            chart: {
                type: 'line'
            },
            title: {
                text: 'Per-Day Traffic Summary'
            },
            yAxis: {
                allowDecimals: false,
                title: {
                    text: 'Units'
                }
            },

            plotOptions: {
                line: {
                    dataLabels: {
                        enabled: true
                    },
                    enableMouseTracking: false
                }
            }

        });


        Highcharts.chart('PerHourTrafficDailyAverageTableGraph', {
            data: {
                table: 'PerHourTrafficDailyAverageTable'
            },
            chart: {
                type: 'line'
            },
            title: {
                text: 'Per-Hour Traffic Daily Average'
            },
            yAxis: {
                allowDecimals: false,
                title: {
                    text: 'Units'
                }
            },

            plotOptions: {
                line: {
                    dataLabels: {
                        enabled: true
                    },
                    enableMouseTracking: false
                }
            },



        });

    </script>




    <script>
        jQuery(document).ready(function ($) {
            $('.counter').counterUp({
                delay: 1,
                time: 100
            });
        });
    </script>

</body>

</html>
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
 
    case $filenameWithExtOnly in
        *Jan* )  
        echo "<a href=\"/emails/data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameWithoutExtension</a>" >> $HTMLOUTPUTDIR/data/jan_rpt.html
        ;;

        *Feb* )  
        echo "<a href=\"/emails/data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameWithoutExtension</a>" >> $HTMLOUTPUTDIR/data/feb_rpt.html
        ;;

        *Mar* )  
        echo "<a href=\"/emails/data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameWithoutExtension</a>" >> $HTMLOUTPUTDIR/data/mar_rpt.html
        ;;

        *Apr* )  
        echo "<a href=\"/emails/data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameWithoutExtension</a>" >> $HTMLOUTPUTDIR/data/apr_rpt.html
        ;;

        *May* )  
        echo "<a href=\"/emails/data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameWithoutExtension</a>" >> $HTMLOUTPUTDIR/data/may_rpt.html
        ;;

        *Jun* )  
        echo "<a href=\"/emails/data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameWithoutExtension</a>" >> $HTMLOUTPUTDIR/data/jun_rpt.html
        ;;                                        

        *Jul* )  
        echo "<a href=\"/emails/data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameWithoutExtension</a>" >> $HTMLOUTPUTDIR/data/jul_rpt.html
        ;;

        *Aug* )  
        echo "<a href=\"/emails/data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameWithoutExtension</a>" >> $HTMLOUTPUTDIR/data/aug_rpt.html
        ;;

        *Sep* )  
        echo "<a href=\"/emails/data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameWithoutExtension</a>" >> $HTMLOUTPUTDIR/data/sep_rpt.html
        ;;

        *Oct* )  
        echo "<a href=\"/emails/data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameWithoutExtension</a>" >> $HTMLOUTPUTDIR/data/oct_rpt.html
        ;;        

        *Nov* )  
        echo "<a href=\"/emails/data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameWithoutExtension</a>" >> $HTMLOUTPUTDIR/data/nov_rpt.html
        ;;      

        *Dec* )  
        echo "<a href=\"/emails/data/${filenameWithoutExtension}.html\" class=\"list-group-item list-group-item-action\">$filenameWithoutExtension</a>" >> $HTMLOUTPUTDIR/data/dec_rpt.html
        ;;          
    esac  
done


#======================================================
# Clean UP
#======================================================
