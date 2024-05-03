import socket
import datetime
import time
import sys
import os.path
from os import path
from datetime import datetime, timedelta
import random
import yaml
import ipaddress
import argparse
from threading import Thread
from os.path import exists
from pytz import timezone
import string
import re
import requests
from requests.auth import HTTPBasicAuth
import json
import logging
import colorlog
from colorlog import ColoredFormatter
import uuid

def writeToFile(text):
    handle = open(strLogFileName, "a")
    handle.write(text + "\n")
    handle.close()

def getSyslogtimeNow(sTimeZone, sRfc, sAddMillisecond):
    # syslogtime now
    now_utc         = datetime.now(timezone('UTC')) + timedelta(milliseconds=sAddMillisecond)

    timeZoneName = sTimeZone
    now_tz = now_utc.astimezone(timezone(timeZoneName))

    if sRfc == "3164":
        sReturn = now_tz.replace(microsecond=0).strftime("%b %d %H:%M:%S")
    elif sRfc == "5424":
        sReturn = now_tz.strftime("%Y-%m-%dT%H:%M:%S.%f%z")
    
    return sReturn

def buildTuples(user, ip):
    random.shuffle(ip)
    random.shuffle(user)
    tuple = list(zip(user, ip))
    return tuple

def randomString(iLen):
    return (''.join(random.choices(string.ascii_uppercase + string.ascii_lowercase + string.digits, k=iLen)))

def randomPublicInternetIpAddr():
    # strRandomIpPartThree = str(random.randint(1, 254))
    # strRandomIpPartFour = str(random.randint(1, 254))
    # strFinalRandomIpConcat = str(strRandomIpPrefix) + strRandomIpPartThree + "." + strRandomIpPartFour
    # octOne = 

    # iStart = 1
    # iEnd = 254
    
    # lExcludeOne = [10, 192, 172, 127, 255, 239, 224, 169]
    # lOctOne = []
    # for x in range(iStart, iEnd):
    #     if not x in lExcludeOne:
    #         lOctOne.append(x)

    lOctOne = [12, 17, 19, 38, 48, 53, 56, 73]
    sOctOne = str(random.choice(lOctOne))
    sOctTwo = str(random.randint(1, 254))
    sOctThree = str(random.randint(1, 254))
    sOctFour = str(random.randint(1, 254))

    sConcat = sOctOne + "." + sOctTwo + "." + sOctThree + "." + sOctFour
    return sConcat

def getPercentage(iA, iB):
    # return what percentage iA is of iB
    # for example, if iA = 10 and iB = 100, percentage would be 10%

    return int(round((iA / iB) * 100, 1))

def betterRandomIntWithMoreRandomness(lBase, lSpikeOne, lSpikeTwo, iRandomHigh):
    # This function works by taking 3 pairs of numbers, as well as a returning a random
    #   value based on a percentage chance

    # iRandomHigh determines the probability of returning a random number in the range from
    #   lSpikeTwo
    # For example, if iRandomHigh is 10, there will be a 1 in 10 chance (1/10) a random number from
    #   the lSpikeTwo range is returned

    # There is a ~90% chance a random value from lBase is returned
    # There is a ~10% chance a random value from lSpikeOne is returned
    # There is a 1/iRandomHigh chance a random value from lSpikeTwo is returned

    # The general idea is you'll want to choose values for the 3 input lists that will be used

    iRandomLow = 1
    # iRandomHigh = 100
    iRandomNum = random.randint(iRandomLow, iRandomHigh)
    iRandomPct = getPercentage(iRandomNum, iRandomHigh)
    
    iRandomReturn = 0
    
    bValidInput = False
    iBaseLow = 0
    iBaseHigh = 0
    iSpikeOneLow = 0
    iSpikeOneLowHigh = 0
    iSpikeTwoLow = 0
    iSpikeTwoHigh = 0
    if len(lBase) == 2:
        iBaseLow = lBase[0]
        iBaseHigh = lBase[1]
    if len(lSpikeOne) == 2:
        iSpikeOneLow = lSpikeOne[0]
        iSpikeOneLowHigh = lSpikeOne[1]
    if len(lSpikeTwo) == 2:
        iSpikeTwoLow = lSpikeTwo[0]
        iSpikeTwoHigh = lSpikeTwo[1]
    if iBaseLow > 0 and iBaseHigh > 0 and iSpikeOneLow > 0 and iSpikeOneLowHigh > 0 and iSpikeTwoLow > 0 and iSpikeTwoHigh > 0:
        bValidInput = True

    if bValidInput == True:
        if iRandomNum == iRandomHigh:
            # very rare, 1 in iRandomHigh chance
            iRandomReturn = random.randint(iSpikeTwoLow, iSpikeTwoHigh)
        elif iRandomPct < 11:
            # 10% chance
            iRandomReturn = random.randint(iSpikeOneLow, iSpikeOneLowHigh)
        else:
            # ~89% chance
            iRandomReturn = random.randint(iBaseLow, iBaseHigh)
    else:
        logger.error("Invalid input for betterRandomIntWithMoreRandomness()")
    
    return iRandomReturn

def getRandomChoiceFromListOfValuesAndListOfWeights(lValues: list, lWeights: list):
    # where k is the number of items in the returned return list
    # we only want 1 value so we return 1
    return random.choices(lValues, weights = lWeights, k = 1)[0]

def dayOfWeekNumToName(iDayOfWeekNum):
    l = [
        "mon",
        "tue",
        "wed",
        "thu",
        "fri",
        "sat",
        "sun"
    ]

    return l[iDayOfWeekNum]

def getDayOfWeekName(argTimezone):
    now_utc         = datetime.now(timezone(argTimezone))
    # iTimeCurHour    = now_utc.hour
    sCurDay         = dayOfWeekNumToName(now_utc.weekday())
    # return "sat"
    return sCurDay

def dayOfWeekMultiplier(iInput, sDayOfWeek, dDayMultiplier):
    d = dDayMultiplier
    # d['mon'] = 1
    # d['tue'] = 1
    # d['wed'] = 1
    # d['thu'] = 1
    # d['fri'] = 1
    # d['sat'] = 0.33
    # d['sun'] = 0.1

    if sDayOfWeek in d:
        iRet = round(iInput * d[sDayOfWeek],2)
        if iRet == 0:
            return 0.01
        else:
            return iRet
    else:
        return iInput

def getHourOfDay(argTimezone):
    now             = datetime.now(timezone(argTimezone))
    return now.hour

def hourofDayMultiplier(iInput: int, iHourOfDay: int, dHourMultiplier: dict):
    if iHourOfDay in dHourMultiplier:
        iRet = round(iInput * dHourMultiplier[iHourOfDay],2)
        if iRet == 0:
            return 0.01
        else:
            return iRet
    else:
        return iInput

def randomHex2Chr():
    chr1 = random.choice('0123456789abcdef')
    chr2 = random.choice('0123456789abcdef')
    return str(chr1) + str(chr2)

def randomHex4Chr():
    chr1 = random.choice('0123456789abcdef')
    chr2 = random.choice('0123456789abcdef')
    chr3 = random.choice('0123456789abcdef')
    chr4 = random.choice('0123456789abcdef')
    return str(chr1) + str(chr2) + str(chr3) + str(chr4)

def getRandomMacAddr():
    dRandomMacVendor = {}
    dRandomMacVendor['intel'] = "38:7a:0e"
    dRandomMacVendor['dell'] = "cc:48:3a"
    dRandomMacVendor['realtek'] = "00:e0:4c"

    listMacsFromVendors = []
    for vendorMac in dRandomMacVendor:
        listMacsFromVendors.append(dRandomMacVendor[vendorMac])
    
    sMacVendor = random.choice(listMacsFromVendors)
    return str(sMacVendor) + ":" + randomHex2Chr() + ":" + randomHex2Chr() + ":" + randomHex2Chr()

def randomGuid():
    return uuid.uuid4()

def generateRandomListOfIpsBasedOnCidrSubnet(sArgCidrSubnet: str):
    lDefaultReturn = ['172.16.200.1']

    if not len(sArgCidrSubnet) > 0:
        return lDefaultReturn
    
    if not re.search("\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/\d{1,2}", str(sArgCidrSubnet)):
        return lDefaultReturn

    lIps = []
    for ip in ipaddress.IPv4Network(sArgCidrSubnet):
        bAddThisIpToList = True

        if re.search("\.0$", str(ip)):
            bAddThisIpToList = False
        
        if bAddThisIpToList == True:
            lIps.append(str(ip))
    
    return lIps

def getRandomLocalLinkIpv6Address():
    # fe80::107d:e407:6f22:8ba6
    string1 = "fe80"    # local link
    string2 = randomHex4Chr()
    string3 = randomHex4Chr()
    string4 = randomHex4Chr()
    string5 = randomHex4Chr()

    return string1 + "::" + string2 + ":" + string3 + ":" + string4 + ":" + string5
 
def replaceAll(x, incrementing_log_msg_number):
        # syslogtime now
        now_utc         = datetime.now(timezone('UTC'))
        # iTimeCurHour    = now_utc.hour
        # iCurDay         = dayOfWeekNumToName(now_utc.weekday())

        timeZoneName = strSyslogTimeZone
        now_tz = now_utc.astimezone(timezone(timeZoneName))

        #not used in windows:
        x = x.replace("__DENIEDPORT", random.choice(getACMEInternalDeniedServicePort))
        x = x.replace("__SPORT", random.choice(getHighSourcePort))
        x = x.replace("__UNTRUSTIP", random.choice(getUntrustIP))
        x = x.replace("__DMZIP", random.choice(getDMZIP))
        x = x.replace("__ALLOWEDPORT", random.choice(getACMEInternalAllowedServicePort))
        x = x.replace("__INTCLIENTIP", random.choice(getDesktopInternalIP))
        x = x.replace("__INTSERVERIP", random.choice(getDesktopInternalIP))
        x = x.replace("__CISCOADMIN", random.choice(getCISCOAdmin))
        x = x.replace("__PUBLICIP", random.choice(getPublicAddress))
        x = x.replace("__ASAHOSTNAME", random.choice(getCISCOASAHostName))
        x = x.replace("__WGHOSTNAME", random.choice(getWATCHGUARDHostName))
        x = x.replace("__DIRECTION", random.choice(getDirection))
        x = x.replace("__CONTYPE", random.choice(getConnectionType))
        x = x.replace("__PROTO", random.choice(getProtocol))
        x = x.replace("__ACLNAME", random.choice(getACLNames))
        x = x.replace("__ACLACTION", random.choice(getACLAction))
        x = x.replace("__GOODURL", random.choice(getGoodURL))
        x = x.replace("__BADURL", random.choice(getGoodURL))
        x = x.replace("__SYSLOGTIME_1", getSyslogtimeNow(strSyslogTimeZone, strSyslogRfcTimestampFormat, 50))
        x = x.replace("__SYSLOGTIME", getSyslogtimeNow(strSyslogTimeZone, strSyslogRfcTimestampFormat, 0))
        # x = x.replace("__SYSLOGTIME", datetime.utcnow().isoformat(timespec='milliseconds')+'Z')
        x = x.replace("__WINDOWSDC", random.choice(getDC))
        x = x.replace("__SUSER", random.choice(getEndUser))
        x = x.replace("__DATETIME", datetime.now(timezone('UTC')).replace(microsecond=0).strftime("%Y-%m-%d %H:%M:%S"))
        x = x.replace("__TIMESTAMP", datetime.now(timezone('UTC')).isoformat(timespec='milliseconds')+'Z')
        x = x.replace("__SUBJECTDOMAINNAME", random.choice(getDomain))
        x = x.replace("__TARGETDOMAINNAME", random.choice(getDomain))
        x = x.replace("__LOGONTYPE", random.choices(getLogonType, weights = [1, 1, 10], k = 1)[0])
        hostname = random.choice(getEndUser) + "-dkstp"
        x = x.replace("__HOSTNAME", hostname)
        tuplepick = random.choice(my_tuples)
        x = x.replace("__DESTHOSTNAME", tuplepick[0] + "-dsktp")
        x = x.replace("__DSTIP", tuplepick[1])
        user = [tuplepick[0], hostname.upper()+'$']
        x = x.replace("__DUSER", random.choice(user))
        x = x.replace("__AUTHPACAKGENAME", random.choice(getAuthenticationPackageName))
        x = x.replace("__WADMIN", random.choice(getWindowsAdmin))
        x = x.replace("__SECGROUP", random.choice(getADGroups))
        x = x.replace("__LOCALSECGROUP", random.choice(getLocalGroup))
        #only for account name change events
        x = x.replace("__NEWUSER", random.choice(getEndUser))
        if "\"_EventID\": 4625" in x:
            x = x.replace("__FAILUREREASON", random.choice(get4625FailureReason))
        if "\"_EventID\": 4776" in x:
            x = x.replace("__FAILUREREASON", random.choice(get4776FailureReason))

       #Applocker only.
        x = x.replace("__APPLOCKERBADAPP", random.choice(getApplockerGoodApps))
        x = x.replace("__APPLOCKERGOODAPP", random.choice(getApplockerBadApps))

        #anomaly
        startTime = datetime.now(timezone('UTC')) - timedelta(minutes=2)
        endTime = datetime.now(timezone('UTC')) + timedelta(minutes=2)
        runTime = datetime.now(timezone('UTC')) + timedelta(minutes=1)
        x = x.replace("__ANOMALYSTART", startTime.isoformat(timespec='milliseconds'))
        x = x.replace("__ANOMALYEND", endTime.isoformat(timespec='milliseconds'))
        x = x.replace("__ANOMALYRUN", runTime.isoformat(timespec='milliseconds'))
        x = x.replace("__ANOMCONFIDENCE", str(round(random.uniform(0.5, 1.0), 2)))
        x = x.replace("__ANOMGRADE", str(round(random.uniform(0.0, 0.2), 2)))
        x = x.replace("__ANOMSCORE", str(round(random.uniform(1, 2), 2)))

        #this will be used for palo alto and cisco asa, used to randomise bytes sent over a connection.
        sentBytes = random.randint(0, 200)
        rcvdBytes = random.randint(0, 200)
        totalBytes = sentBytes + rcvdBytes
        x = x.replace("__TOTALBYTES", str(totalBytes))
        x = x.replace("__SENTBYTES", str(sentBytes))
        x = x.replace("__RCVDBYTES", str(rcvdBytes))

        sentPckts = random.randint(0, 20)
        rcvdPckts = random.randint(0, 20)
        totalPckts = sentPckts + rcvdPckts
        x = x.replace("__TOTALPCKTS", str(totalPckts))
        x = x.replace("__SENTPCKTS", str(sentPckts))
        x = x.replace("__RCVDPCKTS", str(rcvdPckts))

        networkPacketSize = random.randint(63, 1498)
        x = x.replace("__FWPACKETSIZE", str(networkPacketSize))

        networlTtl = random.randint(15, 35)
        x = x.replace("__FWNETWORKTTL", str(networlTtl))

        #for Palo Alto only
        x = x.replace("__PALOSYSLOGTIME", datetime.now(timezone('UTC')).replace(microsecond=0).strftime("%Y-%m-%dT%H:%M:%S-00:00"))
        getPaloSerial = ["007200002536", "007200002537", "007200002538"]
        x = x.replace("__PALO_TIME", datetime.now(timezone('UTC')).replace(microsecond=0).strftime("%Y/%m/%d %H:%M:%S"))
        x = x.replace("__SERIAL", random.choice(getPaloSerial))
        x = x.replace("__SESSIONID", str(random.randint(0,65000)))
        x = x.replace("__DURATION", str(random.randint(0,120)))
        x = x.replace("__SEQNUM", str(random.randint(0,65000)))
        x = x.replace("__INTCLIENTIP", random.choice(getDesktopInternalIP))
        getPaloVsys = ["vsys1", "vsys2"]
        x = x.replace("__VSYS", random.choice(getPaloVsys))
        x = x.replace("__SRCZONE", random.choice(getPaloVsys))
        x = x.replace("__DSTZONE", random.choice(getPaloVsys))
        x = x.replace("__PALO_FLAGS", "0x8000000000000000")
        x = x.replace("__URLCATEGORY", "Allowed")
        #app stuff to be specific this alligns an IP with the relevant MSFT service for known outbound traffic
        pickMSFTService = random.choice(msft_services)
        x = x.replace("__APPNAME", pickMSFTService[0])
        x = x.replace("__MSFTIP", pickMSFTService[1])
        
        getPaloEndReason = ["threat", "policy-deny", "tcp-rst-from-client", "tcp-rst-from-server", "tcp-fin—Both", "aged-out", "unknown"]
        x = x.replace("__SESSION_END_REASON", random.choice(getPaloEndReason))
        x = x.replace("__COUNTRYNAME", "United Kingdom")
        x = x.replace("__PALOHOSTHAME", "palo01")
        tuple1 = random.choice(VPN_tuples)
        x = x.replace("__VPNUSER", tuple1[0])
        x = x.replace("__VPNIP", tuple1[1])

        #Microsoft Windows 7  Service Pack 1, 64-bit
        getPaloClientOS = ["Browser", "Windows"]
        paloClientOS = random.choice(getPaloClientOS)
        x = x.replace("__CLIENTOS", paloClientOS)
        if paloClientOS == "Windows":
            x = x.replace("__AUTHMECH", "LDAP")
            x = x.replace("__CLIENTVERS", "Microsoft Windows 7 Service Pack 1, 64-bit")
        else: 
            x = x.replace("__AUTHMECH", "SAML")
            x = x.replace("\"__CLIENTVERS\"", "")
        x = x.replace("__PORTALNAME", random.choice(getFQDN))

        sRdmEPort = random.randrange(32768,60999)
        x = x.replace("__EPHEMERALPORT", str(sRdmEPort))

        # ================= Cloudflare START =============================
        # Cloudflare
        sRdmCfLowBotScore = random.randrange(10,29)
        x = x.replace("__CFBotScoreSubThirty", str(sRdmCfLowBotScore))
        x = x.replace("__CFBotScoreNotABot", str(random.randrange(10,29)))
        x = x.replace("__CFBotScoreSrc", random.choice(listClFlBotScoreSrc))

        sClFlCacheStatus = random.choices(listClFlCacheCacheStatusValues, weights = listClFlCacheCacheStatusWeights, k = 1)[0]
        x = x.replace("__CFCacheCacheStatus", sClFlCacheStatus)

        # we must accomdate how cache bytes is linked to weather we had a successful cache hit
        #   it doesn't make any sense to return a cache bytes value if no cache was hit
        # 
        # success cache
        if sClFlCacheStatus == 'hit':
            iClFlCacheBytes = random.randint(200, 1498)
            x = x.replace("__CFCacheTieredFill", str(random.choice([True, False])))
        else:
            iClFlCacheBytes = 0
            x = x.replace("__CFCacheTieredFill", str(False))
        x = x.replace("__CFCacheResponseBytes", str(iClFlCacheBytes))

        dictClFlBadIpInfo = random.choice(listClFlBadClientIpInfo)
        x = x.replace("__CFBadClientASN", str(dictClFlBadIpInfo['ClientASN']))
        x = x.replace("__CFBadClientCountry", str(dictClFlBadIpInfo['ClientCountry']))
        x = x.replace("__CFBadClientIPClass", str(dictClFlBadIpInfo['ClientIPClass']))
        x = x.replace("__CFBadClientIP", str(dictClFlBadIpInfo['ClientIP']))

        x = x.replace("__CFGoodClientIP", str(randomPublicInternetIpAddr()))

        iClFlReqBytes = random.randint(999, 4000)
        x = x.replace("__CFClientRequestBytes", str(iClFlReqBytes))
        x = x.replace("__CFClientRequestHost", str(strClFlClientRequestHost))
        strBuildClientRequestReferer = "https://" + strClFlClientRequestHost + "/"
        x = x.replace("__CFClientRequestReferer", str(strBuildClientRequestReferer))
        
        # listClFlClientRequestURI
        # str("/?id=" + randomString(16))
        listTmpReqUri = []
        listTmpReqUri.clear()
        listTmpReqUri.extend(listClFlClientRequestURI)
        listTmpReqUri.append(str("/?id=" + randomString(16)))
        x = x.replace("__CFClientRequestURI", random.choice(listTmpReqUri))

        sClFlClientRequestUserAgent = random.choices(listClFlClientRequestUserAgentValues, weights = listClFlClientRequestUserAgentWeights, k = 1)[0]
        x = x.replace("__CFClientRequestUserAgent", sClFlClientRequestUserAgent)
        
        x = x.replace("__CFBotClientRequestUserAgent", random.choices(ClFlBotClientReqUserAgt['values'], weights = ClFlBotClientReqUserAgt['weights'], k = 1)[0])

        strClFlClientSSLProtocolRandom = random.choices(strClFlClientSSLProtocolValues, weights = strClFlClientSSLProtocolWeights, k = 1)[0]
        x = x.replace("__ClientSSLProtocol", strClFlClientSSLProtocolRandom)

        if strClFlClientSSLProtocolRandom == "TLSv1.2":
            sKeyForClientCiphers = "ClientSSLCipherTLS12"
        elif strClFlClientSSLProtocolRandom == "TLSv1.3":
            sKeyForClientCiphers = "ClientSSLCipherTLS13"
        
        listForSslCipherValues = listClFlClientCiphers[sKeyForClientCiphers]['values']
        listforSslCipherWeights = listClFlClientCiphers[sKeyForClientCiphers]['weights']

        sClFlFinalForSslCipher = random.choices(listForSslCipherValues, weights = listforSslCipherWeights, k = 1)[0]
        x = x.replace("__CFClientSSLCipher", sClFlFinalForSslCipher)

        sRdmCfClPort = random.randrange(32768,60999)
        x = x.replace("__CFClientSrcPort", str(sRdmCfClPort))
        
        x = x.replace("__CFEdgePathingOp", str(random.choices(listClFlbadEdgePathingOp['values'], weights = listClFlbadEdgePathingOp['weights'], k = 1)[0]))
    
        # iRandomForEdgeResponseBytes = random.randint(1, 700)
        # if iRandomForEdgeResponseBytes == 700:
        #     iEdgRspBytes = random.randint(1000000, 2000000)
        # else:
        #     iRandomForEdgeResponseBytesSlightlySpiky = random.randint(1, 10)
        #     if iRandomForEdgeResponseBytesSlightlySpiky == 10:
        #         iEdgRspBytes = random.randint(100, 7500)
        #     else:
        #         iEdgRspBytes = random.randint(100, 7500)
        iEdgRspBytes = betterRandomIntWithMoreRandomness([100,7500], [10000,100000], [1000000, 2000000], 500)
        x = x.replace("__CFEdgeResponseBytes", str(iEdgRspBytes))

        strClFlHostName = strClFlEdgeRequestHostPrefix + str(random.randint(1, 12))
        x = x.replace("__CFEdgeRequestHost", str(strClFlHostName))

        strRandomIpPrefix = random.choice(listClFlEdgeServerIPPrefix)
        strRandomIpPartThree = str(random.randint(1, 254))
        strRandomIpPartFour = str(random.randint(1, 254))
        strFinalRandomIpConcat = str(strRandomIpPrefix) + strRandomIpPartThree + "." + strRandomIpPartFour
        x = x.replace("__CFEdgeServerIP", str(strFinalRandomIpConcat))

        strRandomInternalIpPrefix = strClFlOriginIPPrefix
        strRandomIpPartFour = str(random.randint(13, 77))
        strFinalRandomInternalIp = str(strRandomInternalIpPrefix) + strRandomIpPartFour
        x = x.replace("__CFOriginIP", str(strFinalRandomInternalIp))

        x = x.replace("__CFEdgeResponseContentType", str(random.choices(listClFlEdgeResponseContentType['values'], weights = listClFlEdgeResponseContentType['weights'], k = 1)[0]))

        x = x.replace("__CFClientRequestProtocol", str(random.choices(listClFlClientRequestProtocol['values'], weights = listClFlClientRequestProtocol['weights'], k = 1)[0]))

        x = x.replace("__CFClientRequestMethod", str(random.choices(listClFlClientRequestMethod['values'], weights = listClFlClientRequestMethod['weights'], k = 1)[0]))

        # iRandomForHighResponseTime = random.randint(1, 700)
        # if iRandomForHighResponseTime == 700:
        #     iRespTimeMs = random.randint(1000, 3000)
        # else:
        #     iRandomForSlightlyHigherResponseTime = random.randint(1, 10)
        #     if iRandomForSlightlyHigherResponseTime == 10:
        #         iRespTimeMs = random.randint(250, 455)
        #     else:
        #         iRespTimeMs = random.randint(50, 200)
        iRespTimeMs = betterRandomIntWithMoreRandomness([50,150], [175,350], [400, 3000], 5000)
        x = x.replace("__CFOriginResponseTime", str(iRespTimeMs))

        x = x.replace("__CFEdgeResponseStatus", str(random.choices(listClFlEdgeResponseStatus['values'], weights = listClFlEdgeResponseStatus['weights'], k = 1)[0]))
        # ================= Cloudflare END ===============================

        x = x.replace("__NATIP", random.choice(lNatIps))
        iFirewallTrafficDuration = betterRandomIntWithMoreRandomness([1,2], [3,4], [5, 6], 7)
        x = x.replace("__FWTRAFFICDURATION", str(iFirewallTrafficDuration))

        # Fortinet
        x = x.replace("__FTNlogId", str(incrementing_log_msg_number))
        # __FTNdate     YYYY-MM-DD
        # __FTNtime     HH:MM:SS
        
        x = x.replace("__FTNdate", str(now_tz.replace(microsecond=0).strftime("%Y-%m-%d")))
        x = x.replace("__FTNtime", str(now_tz.replace(microsecond=0).strftime("%H:%M:%S")))
        x = x.replace("__RDMMACADDR", str(getRandomMacAddr()))
        # x = x.replace("__FTNDnsQuery", str('qname="changelogs.ubuntu.com" qtype="AAAA" qtypeval=28'))
        
        dDnsQandRsp = random.choices(listDnsQueryAndResponses['values'], weights = listDnsQueryAndResponses['weights'], k = 1)[0]
        x = x.replace("__FTNDnsQuery", str('qname="' + dDnsQandRsp['name'] + '" qtype="' + dDnsQandRsp['querytype'] + '" qtypeval=' + dDnsQandRsp['querytypevalue'] + ''))

        dDnsBlockedQandRsp = random.choices(listDnsBlockedQueryAndResponses['values'], weights = listDnsBlockedQueryAndResponses['weights'], k = 1)[0]
        x = x.replace("__FTNDnsBlockedQuery", str('qname="' + dDnsBlockedQandRsp['name'] + '" qtype="' + dDnsBlockedQandRsp['querytype'] + '" qtypeval=' + dDnsBlockedQandRsp['querytypevalue'] + ''))

        x = x.replace("__FWRDMSENDBYTES", str(betterRandomIntWithMoreRandomness([1,200], [300,500], [600, 800], 500)))
        x = x.replace("__FWRDMRECVBYTES", str(betterRandomIntWithMoreRandomness([1,200], [300,500], [600, 800], 500)))

        # dEmailVirus = random.choices(listEmailVirus['values'], weights = listEmailVirus['weights'], k = len(listEmailVirus['values']))[0]
        dEmailVirus = getRandomChoiceFromListOfValuesAndListOfWeights(listEmailVirus['values'], listEmailVirus['weights'])
        x = x.replace("__EMAILVIRUSNAME", str(dEmailVirus['name']))
        x = x.replace("__EMAILVIRUSACTION", str(dEmailVirus['action']))

        sSeverityIps = getRandomChoiceFromListOfValuesAndListOfWeights(listSeverityLevelIps['values'], listSeverityLevelIps['weights'])
        x = x.replace("__LEVELIPS", str(sSeverityIps))

        x = x.replace("__MALICOUSURLHOSTNAME", str(dDnsBlockedQandRsp['name']))

        # IPv6
        x = x.replace("__IPV6RANDOMLOCALLINK", str(getRandomLocalLinkIpv6Address()))
        x = x.replace("__IPV6RANDOMMULTICAST", str(getRandomChoiceFromListOfValuesAndListOfWeights(out["firewall_generic"]["ipv6_multicast"]['values'], out["firewall_generic"]["ipv6_multicast"]['weights'])))

        x = x.replace("__NGINXDATETIME", datetime.now(timezone('UTC')).replace(microsecond=0).strftime("%d/%b/%Y:%H:%M:%S"))

        x = x.replace("__PFSENSEHTTPREQPATH_POST", str(getRandomChoiceFromListOfValuesAndListOfWeights(out["pfsense"]["http_request_path"]["post"]['values'], out["pfsense"]["http_request_path"]["post"]['weights'])))
        x = x.replace("__PFSENSEHTTPREQPATH_GET", str(getRandomChoiceFromListOfValuesAndListOfWeights(out["pfsense"]["http_request_path"]["get"]['values'], out["pfsense"]["http_request_path"]["get"]['weights'])))

        # Microsoft365 / m365
        d_external_user = getRandomChoiceFromListOfValuesAndListOfWeights(
            out["external_users"]['values'],
            out["external_users"]['weights']
        )
        x = x.replace("__EXTERNALUSERNAME", str(d_external_user['user_name']))
        x = x.replace("__EXTERNALUSERDOMAIN", str(d_external_user['user_domain']))
        x = x.replace("__EXTERNALUSERIP", str(d_external_user['public_ip_addr']))
        x = x.replace("__EXTERNALUSERGUID", str(d_external_user['user_guid']))
        x = x.replace("__EXTERNALUSERUSERAGENT", str(d_external_user['user_agent']))
        x = x.replace("__EXTERNALUSERORGID", str(d_external_user['org_id']))
        x = x.replace("__EXTERNALUSERMAILBOXOWNERSID", str(d_external_user['mailbox_owner_sid']))
        x = x.replace("__EXTERNALUSERCODE", str(d_external_user['user_code']))

        d_external_admin_user = getRandomChoiceFromListOfValuesAndListOfWeights(
            out["m365_admin_users"]['values'],
            out["m365_admin_users"]['weights']
        )
        x = x.replace("__EXTERNALADMINUSERGUID", str(d_external_admin_user['user_guid']))
        x = x.replace("__EXTERNALADMINUSERNAME", str(d_external_admin_user['user_name']))
        x = x.replace("__EXTERNALADMINUSERCODE", str(d_external_admin_user['user_code']))

        x = x.replace("__RANDOMGUID", str(randomGuid()))

        d_random_file = getRandomChoiceFromListOfValuesAndListOfWeights(
            out["random_file_name"]['values'],
            out["random_file_name"]['weights']
        )
        x = x.replace("__FILESOURCENAME", str(d_random_file["filename"]))
        x = x.replace("__FILEHTTPURI", str(d_random_file["http_uri"]))
        x = x.replace("__FILEHTTPRELATIVEURL", str(d_random_file["relative_url"]))

        d_file_move_destination = getRandomChoiceFromListOfValuesAndListOfWeights(
            out["random_file_move_destination"]['values'],
            out["random_file_move_destination"]['weights']
        )
        x = x.replace("__FILEmOVEdESTINATIONrELATIVEuRL", str(d_file_move_destination["relative_url"]))
        x = x.replace("__FILEmOVEdESTINATIONnAME", str(d_file_move_destination["name"]))
        x = x.replace("__FILEmOVEdESTINATIONfILEeXT", str(d_file_move_destination["file_ext"]))

        
        
        

        return x

#adding for palo alto to decide on VPN user/ip pairs
def buildVPNTuples(user, ip):
    random.shuffle(user)
    random.shuffle(ip)
    tuple = list(zip(user, ip))
    return tuple;

def msgPerSecRangeForInput(strArgInput, dictArgInputs):
    if "msg_per_sec_range" in dictArgInputs:
        return dictArgInputs['msg_per_sec_range']
    
    return [2,2]

def multiMessageSupport(sInput):
    # lOutput = []
    x = sInput.split("__NEWLINE")
    # exit()
    return x

def getLastPartAfterChar(origString: str, splitChar: str):
    spl = origString.split(splitChar)
    if len(spl):
        index = len(spl)-1
        return spl[index].lower()

def getFirstPartOfSplit(origString: str, splitChar: str):
    spl = origString.split(splitChar)
    if len(spl):
        return spl[0]

def removeKeysFromDict(dOrigdict: dict, lKeysToRemove: list):
    for item in lKeysToRemove:
        if item in dOrigdict:
            dOrigdict.pop(item)
    
    return dOrigdict

def expandMsgFile(origMsg: str):
    if origMsg.startswith("____"):
        logFileToExpand = "/".join([base_path, origMsg.strip().replace("____", "")])
        # logger.debug("".join(["Msg starts with ____, will expand referneced file: '", logFileToExpand, "'"]))
        if exists(logFileToExpand):
            fExt = getLastPartAfterChar(logFileToExpand, ".")
            fo = open(logFileToExpand, "r")
            content = fo.read()
            fo.close()

            if fExt == "json":
                oJson = json.loads(content)
                
                # extra fun stuff
                bMagicReplacements = False
                sMagicMessageType = ""
                if "hidden_and_reserved" in oJson:
                    if "magic_replacements" in oJson["hidden_and_reserved"]:
                        bMagicReplacements = True
                    
                    if bMagicReplacements == True:
                        if "message_type" in oJson["hidden_and_reserved"]:
                            sMagicMessageType = str(oJson["hidden_and_reserved"]["message_type"])

                lRemove = ["_id", "gim_tags", "gl2_accounted_message_size", "gl2_message_id", "gl2_source_input", "gl2_source_node", "source_as_number", "source_as_organization", "source_geo_city", "source_geo_coordinates", "source_geo_country", "source_geo_country_iso", "source_ip_city_name", "source_ip_country_code", "source_ip_geolocation", "streams", "timestamp", "o365_client_ip_city_name", "o365_client_ip_country_code", "o365_client_ip_geolocation"]
                oJson = removeKeysFromDict(oJson, lRemove)

                if bMagicReplacements == True:
                    # autoRepalcements
                    if sMagicMessageType == "m365":
                        if "user_name" in oJson:
                            oJson["user_name"] = "__EXTERNALUSERNAME"
                        if "o365_object_id" in oJson:
                            oJson["o365_object_id"] = "__EXTERNALUSERNAME"
                        if "source_ip" in oJson:
                            oJson["source_ip"] = "__EXTERNALUSERIP"
                        if "o365_client_ip" in oJson:
                            oJson["o365_client_ip"] = "__EXTERNALUSERIP"
                        if "o365_client_info_string" in oJson:
                            oJson["o365_client_info_string"] = "Client=OWA;__EXTERNALUSERUSERAGENT"
                        if "user_domain" in oJson:
                            oJson["user_domain"] = "__EXTERNALUSERDOMAIN"
                        if "email_mailbox_owner_name" in oJson:
                            oJson["email_mailbox_owner_name"] = "__EXTERNALUSERNAME"
                        if "o365_org_id" in oJson:
                            oJson["o365_org_id"] = "__EXTERNALUSERORGID"
                        if "o365_target_org_id" in oJson:
                            oJson["o365_target_org_id"] = "__EXTERNALUSERORGID"
                        if "email_mailbox_owner_id" in oJson:
                            oJson["email_mailbox_owner_id"] = "__EXTERNALUSERMAILBOXOWNERSID"
                        if "user_email" in oJson:
                            oJson["user_email"] = "__EXTERNALUSERCODE@__EXTERNALUSERDOMAIN"
                        if "o365_user_id" in oJson:
                            oJson["o365_user_id"] = "__EXTERNALUSERMAILBOXOWNERSID"
                        if "user_id" in oJson:
                            oJson["user_id"] = "__EXTERNALUSERNAME"
                        if "o365_actor_org_id" in oJson:
                            oJson["o365_actor_org_id"] = "__EXTERNALADMINUSERGUID"
                        if "trace_id" in oJson:
                            oJson["trace_id"] = "__RANDOMGUID"
                        if "http_user_agent" in oJson:
                            oJson["http_user_agent"] = "__EXTERNALUSERUSERAGENT"
                        if "file_source_name" in oJson:
                            oJson["file_source_name"] = "__FILESOURCENAME"
                        if "message" in oJson:
                            if re.search("\[[^\]]+\] : \[[^\]]+\]", str(oJson["message"])):
                                oJson["message"] = re.sub("\[[^\]]+\] : \[[^\]]+\]", "[__EXTERNALUSERNAME] : [__EXTERNALUSERIP]", oJson["message"])
                        
                        if "sub_message_type" in oJson["hidden_and_reserved"]:
                            if (oJson["hidden_and_reserved"]["sub_message_type"] == "onedrive" or
                                oJson["hidden_and_reserved"]["sub_message_type"] == "sharepoint"
                                ):
                                if "o365_object_id" in oJson:
                                    oJson["o365_object_id"] = "__FILEHTTPURI__FILEHTTPRELATIVEURL/__FILESOURCENAME"
                                if "http_uri" in oJson:
                                    oJson["http_uri"] = "__FILEHTTPURI"
                                if "o365_destination_relative_url" in oJson:
                                    oJson["o365_destination_relative_url"] = "__FILEmOVEdESTINATIONrELATIVEuRL"
                                if "file_destination_name" in oJson:
                                    oJson["file_destination_name"] = "__FILEmOVEdESTINATIONnAME"
                                if "file_extension_destination" in oJson:
                                    oJson["file_extension_destination"] = "__FILEmOVEdESTINATIONfILEeXT"
                
                oJson = removeKeysFromDict(oJson, ["hidden_and_reserved"])
                
                return json.dumps(oJson)

    return origMsg

def graylogApiConfigIsValid(noAuth: bool):
    if 'https' in dictGraylogApi:
        if not dictGraylogApi['https'] == True and not dictGraylogApi['https'] == False:
            logger.error("Graylog API Config: https not set to true or false.")
            return False
    else:
        logger.error("Graylog API Config: https not set")
        return False
    
    if 'host' in dictGraylogApi:
        if not len(dictGraylogApi['host']) > 0:
            logger.error("Graylog API Config: host value length is 0")
            return False
    else:
        logger.error("Graylog API Config: host not set")
        return False

    if 'port' in dictGraylogApi:
        if not len(dictGraylogApi['port']) > 0 and not int(dictGraylogApi['port']) > 0:
            logger.error("Graylog API Config: port value is empty")
            return False
    else:
        logger.error("Graylog API Config: port not set")
        return False

    if 'graylog_api_token' in dictGraylogApi:
        # token is empty
        if not len(dictGraylogApi['graylog_api_token']) > 0:
            if noAuth == False:
                # check if username and password is set
                if 'username' in dictGraylogApi and 'password' in dictGraylogApi:
                    if len(dictGraylogApi['username']) and len(dictGraylogApi['password']) > 0:
                        return True
                    else:
                        logger.error("Graylog API Config: username and password empty")
                        return False

                logger.error("Graylog API Config: username and password not set")
                return False
    else:
        logger.error("Graylog API Config: graylog_api_token not set")
        return False
    
    return True

def mergeDict(dictOrig: dict, dictToAdd: dict, allowReplacements: bool):
    for item in dictToAdd:
        
        bSet = True
        if item in dictOrig:
            if allowReplacements == False:
                bSet = False
        
        if bSet == True:
            dictOrig[item] = dictToAdd[item]
    
    return dictOrig

def doGraylogApi(argMethod: str, argApiUrl: str, argHeaders: dict, argJson: str, argExpectedReturnCode: int, argReturnJson: bool, noAuth: bool):
    if graylogApiConfigIsValid(noAuth) == True:
        # build URI
        sArgBuildUri = ""
        if dictGraylogApi['https'] == True:
            sArgBuildUri = "https://"
        else:
            sArgBuildUri = "http://"

        sArgHost = dictGraylogApi['host']
        sArgPort = dictGraylogApi['port']

        if len(dictGraylogApi['username']) > 0 and len(dictGraylogApi['password']) > 0:
            sArgUser = dictGraylogApi['username']
            sArgPw = dictGraylogApi['password']
        elif len(dictGraylogApi['graylog_api_token']) > 0:
            sArgUser = dictGraylogApi['graylog_api_token']
            sArgPw = "token"

        # dictGraylogApi['graylog_api_token']

        # print(alertText + "Graylog Server: " + sArgHost + defText + "\n")

        # build server:host and concat with URI
        sArgBuildUri=sArgBuildUri+sArgHost+":"+sArgPort
        
        sUrl = sArgBuildUri + argApiUrl

        # add headers
        sHeaders = {"Accept":"application/json", "X-Requested-By":"python-ctpk-upl"}
        sHeaders = mergeDict(sHeaders, argHeaders, True)
        
        if argMethod.upper() == "GET":
            try:
                r = requests.get(sUrl, headers=sHeaders, verify=False, auth=HTTPBasicAuth(sArgUser, sArgPw), timeout=5)
            except Exception as e:
                return {
                    "success": False,
                    "exception": e
                }
        elif argMethod.upper() == "POST":
            try:
                r = requests.post(sUrl, json = argJson, headers=sHeaders, verify=False, auth=HTTPBasicAuth(sArgUser, sArgPw))
            except Exception as e:
                return {
                    "success": False,
                    "exception": e
                }
        
        if r.status_code == argExpectedReturnCode:
            if argReturnJson:
                return {
                    "json": json.loads(r.text),
                    "status_code": r.status_code,
                    "success": True
                }
            else:
                return {
                    "text": r.text,
                    "status_code": r.status_code,
                    "success": True
                }
        else:
            return {
                "status_code": r.status_code,
                "success": False,
                "failure_reason": "Return code " + str(r.status_code) + " does not equal expected code of " + str(argExpectedReturnCode),
                "text": r.text
            } 
    else:
        return {"exception": "api_not_configured", "success": False}

def getGraylogInputs():
    r = doGraylogApi("GET", "/api/system/inputs", {}, {}, 200, True, False)
    if "json" in r:
        return r['json']

    return ""

def doesGraylogInputExist(argInputType: str, argPort: int):
    dInputsFromApi = getGraylogInputs()
    
    # json_object = json.dumps(dInputsFromApi, indent = 4)

    if len(dInputsFromApi) > 0:
        if "inputs" in dInputsFromApi:
            if len(dInputsFromApi['inputs']) == 0:
                return False
        
        for input in dInputsFromApi['inputs']:
            if input['type'].lower() == argInputType.lower() and int(input['attributes']['port']) == int(argPort):
                return True

            # input['type']
            # input['attributes']['port']
        
    
    return False

def getInputConfJson(argInputType: str, argPort: int):
    if argInputType.lower() == "org.graylog2.inputs.syslog.tcp.syslogtcpinput":
        d = {
            "title": "Log Replay - Syslog TCP",
            "type": "org.graylog2.inputs.syslog.tcp.SyslogTCPInput",
            "configuration": {
                "bind_address": "0.0.0.0",
                "port": argPort,
                "recv_buffer_size": 1048576,
                "number_worker_threads": 2,
                "tls_cert_file": "",
                "tls_key_file": "",
                "tls_enable": False,
                "tls_key_password": "",
                "tls_client_auth": "disabled",
                "tls_client_auth_cert_file": "",
                "tcp_keepalive": False,
                "use_null_delimiter": False,
                "max_message_size": 2097152,
                "override_source": None,
                "charset_name": "UTF-8",
                "force_rdns": False,
                "allow_override_date": True,
                "store_full_message": False,
                "expand_structured_data": False
            },
            "global": True
        }
        return d
    elif argInputType.lower() == "org.graylog2.inputs.gelf.udp.gelfudpinput":
        d = {
            "title": "Log Replay - Gelf UDP",
            "type": "org.graylog2.inputs.gelf.udp.GELFUDPInput",
            "configuration": {
                "bind_address": "0.0.0.0",
                "port": argPort,
                "recv_buffer_size": 262144,
                "number_worker_threads": 2,
                "override_source": None,
                "charset_name": "UTF-8",
                "decompress_size_limit": 8388608
            },
            "global": True
        }
        return d
    elif argInputType.lower() == "org.graylog.integrations.inputs.paloalto9.paloalto9xinput":
        d = {
            "title": "Log Replay - Palo 9+",
            "type": "org.graylog.integrations.inputs.paloalto9.PaloAlto9xInput",
            "configuration": {
                "bind_address": "0.0.0.0",
                "port": argPort,
                "recv_buffer_size": 1048576,
                "number_worker_threads": 2,
                "tls_cert_file": "",
                "tls_key_file": "",
                "tls_enable": False,
                "tls_key_password": "",
                "tls_client_auth": "disabled",
                "tls_client_auth_cert_file": "",
                "tcp_keepalive": False,
                "use_null_delimiter": False,
                "max_message_size": 2097152,
                "timezone": "UTC",
                "store_full_message": False
            },
            "global": True
        }
        return d

    return False

def createGraylogInput(argInputType: str, argPort: int):
    inputConfJson = getInputConfJson(argInputType, argPort)
    logger.debug("".join(["Creating input ", str(argInputType)]))
    logger.debug("".join(["Input Creation Config: ", json.dumps(inputConfJson, indent = 4)]))
    
    r = doGraylogApi("POST", "/api/system/inputs", {}, inputConfJson, 201, True, False)
    if "success" in r:
        if r['success'] == True:
            return True
        else:
            logger.error(r)
    
    return False

def sendEvents(HOST, PORT, PROTO, inputName, events_file, epsRange):
    secSleepBuffer = 0
    iSocketRetries = 0
    iSocketInitialRetryBackOff = iSocketRetryWaitSec
    # HOST              to send logs to
    # PORT              to send to
    # PROTO             protocol tcp|udp
    # inputName         name of input as declared by the key of this entry in the config yaml
    # event_type        file name of events to send
    # epsRange          list of 2 numbers that specify the range used to generate random number. [1, 2]

    sock = sockConnHandling(HOST, PORT, PROTO, inputName)

    eps = 0
    count = 0
    myArr = []
    myArr2 = []
    #build events array
    # open specified events file
    with open(events_file, "r") as x:
        # for each line
        for t in x:
            b_ok_to_proceed = True
            first_char = t[0]

            # ignore lines that start with #
            if first_char == "#":
                b_ok_to_proceed = False
            
            # ignore empty lines
            if first_char == "\n":
                b_ok_to_proceed = False
            
            if not "|" in t:
                b_ok_to_proceed = False

            if b_ok_to_proceed == True:
                # split line by |
                test = t.partition("|")
                # note: this outputs
                #   0   weight
                #   1   |
                #   2   log line
                
                # weight - how likely this event will be chosen at random to be sent
                #   higher numbers have a higher chance of being sent.
                myArr2.append(float(test[0]))

                # event to send
                myArr.append(test[2])

    while count < loglines:
        if secSleepBuffer >= 60:
            logger.info("".join([str(count), " events have been sent for ", inputName, " - ", str(PROTO), " ", str(HOST), ":", str(PORT)]))
            secSleepBuffer = 0

        # choose an event to send at random
        mystr = random.choices(myArr, weights = myArr2, k = 1)[0]
        # add ability to expand a message file

        try:
            origMystr = mystr
            mystr = expandMsgFile(mystr)
        except Exception as e:
            logger.error("".join(["Exception attempting expandMsgFile(): ", str(e)]))
            mystr = origMystr
        
        lMsgsToSend = []

        #need to add this in because the palo input expects an explicit new line but python will escape these chars if written in the events file.
        if inputName == "palo_alto":
            strFinal = replaceAll(mystr + "\n", count)
        else:
            strFinal = replaceAll(mystr, count)

        lMsgsToSend = multiMessageSupport(strFinal)
        
        if args.debug == False:
            for msg in lMsgsToSend:
                msg = msg + "\n"

                encoded = msg.encode('utf-8')
                # exception handling
                try:
                    bExceptionOccured = True
                    sock.send(encoded)
                    bExceptionOccured = False
                except Exception as e:
                    bExceptionOccured = True
                
                if bExceptionOccured == True:
                    logger.error("".join(["Socket send error! - ", inputName, " - ", str(PROTO), " ", str(HOST), ":", str(PORT)]))
                    logger.info("".join(["Waiting ", str(iSocketInitialRetryBackOff), "s, Max backoff: ", str(iSocketRetryBackOffMaxSec), "s..."]))
                    # sleep for X seconds
                    time.sleep(iSocketInitialRetryBackOff)

                    # Increment socket retry count
                    iSocketRetries = iSocketRetries + 1
                    
                    # If the number of retries exceeds the intial backoff retry grace count
                    #   Don't apply backoff for the first X number of retries in case the error was short lived
                    if iSocketRetries > iSocketRetryBackOffGraceCount:
                        # if backoff value is less than max, keep adding backoff value to delay
                        if iSocketInitialRetryBackOff < iSocketRetryBackOffMaxSec:
                            iSocketInitialRetryBackOff = iSocketInitialRetryBackOff + iSocketRetryBackOffSec

                        # if backoff value exceeds max, set to max
                        if iSocketInitialRetryBackOff > iSocketRetryBackOffMaxSec:
                            iSocketInitialRetryBackOff = iSocketRetryBackOffMaxSec

                    # If socket retries exceeds max, exit script
                    if iSocketRetries > iSocketMaxRetries:
                        logger.critical("FATAL: To many socket retries. Exiting.")
                        exit()
                    
                    logger.info("".join(["Retry ", str(iSocketRetries), " of ", str(iSocketMaxRetries)]))

                    # retry socket
                    sock = sockConnHandling(HOST, PORT, PROTO, inputName)
                    # no amount of troubleshooting has allowd me to figure out why each time this for loops runs
                    #   the try/except above for sock.send occurs 2 times,
                    #   the 1st attempt fails, but the second does not and incorrectly resets the state
                    #   below with the `if iSocketRetries > 0:` condition
                    #   for whatever reason, placing this second `sock.send` appears to fix this???
                    #   in any case without this, the max retries scenario will never occur
                    try:
                        sock.send(encoded)
                    except:
                        abc = "xyz"
                else:
                    if iSocketRetries > 0:
                        logger.debug("".join(["RECONNECTED: Socket and send errors resolved. Sending messages again. ", "\n", "iSocketRetries = 0", "\n", "iSocketInitialRetryBackOff = ", str(iSocketRetryWaitSec)]))
                        # reset retry counter
                        iSocketRetries = 0
                        # reconnected and it feels SO good
                        logger.info("".join(["RECONNECTED: Sending Events - ", inputName, " - ", str(PROTO), " ", str(HOST), ":", str(PORT)]))
                        # reset backoff to initial value
                        iSocketInitialRetryBackOff = iSocketRetryWaitSec

        else:
            logger.debug("".join(["Debug is enabled, skipping sock.send -  ", inputName, " - ", str(PROTO), " ", str(HOST), ":", str(PORT)]))
        
        if bVerbose == True:
            for msg in lMsgsToSend:
                logger.debug(msg)

        # get random number from range of EPS for specified event
        # For example, if the range is 1-3, this will add a multiplier that performs a sleep
        #   for a shorter amount of time to allow more more events in a given second
        #   A range of 1-3 will have a random change of genearing between 1 and 3 events per second
        iRandEps = int(random.randint(int(epsRange[0]), int(epsRange[1])))

        # Declare a var we can use to add additional EPS multipliers
        #   Such as
        #       Day of Week
        #       Hour of Day
        epsMultiplier = iRandEps

        # Adjust EPS multiplier based on config, based on Day of week
        #   For example, Saturday or Sunday can be configured to send fewer EPS
        #   simulating lower log volume on the weekend
        if enableRandomEpsByDayOfWeek == True:
            epsMultiplier = dayOfWeekMultiplier(epsMultiplier,str(getDayOfWeekName(strSyslogTimeZone)), randomEpsByDayOfWeekMultipliers)
        
        # Adjust EPS multiplier based on config, based on Hour of Day
        if enableRandomEpsByHourOfDay == True:
            epsMultiplier = hourofDayMultiplier(epsMultiplier, getHourOfDay(strSyslogTimeZone), epsByHourOfDayMultipliers)

        iSecondsToSleepFor = 1/epsMultiplier

        if args.verbose == True:
            print("Sleep: " + str(iSecondsToSleepFor))

        time.sleep(iSecondsToSleepFor)
        secSleepBuffer = secSleepBuffer + iSecondsToSleepFor
        count+= 1
#echo '{"version": "1.1","host":"example.org","short_message":"A short message that helps you identify what is going on","full_message":"Backtrace here\n\nmore stuff","level":1,"_user_id":9001,"_some_info":"foo","_some_env_var":"bar"}' | nc -w 1 127.0.0.1 5044

def getSocket(sArtProtocol):
    if sArtProtocol == "UDP":
        return socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    elif sArtProtocol == "TCP":
        return socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    else:
        logger.error("Invalid socket protocol specified. Must be UDP or TCP.")

def sockConnHandling(HOST, PORT, PROTO, inputName):
    sock = getSocket(PROTO)
    if args.debug == False:
        # Open socket to specified Host and Port
        try:
            logger.debug("".join(["socket connect for ", str(inputName) ," - ", str(HOST), ":", str(PORT)]))
            sock.connect((HOST, PORT))
        except Exception as e:
            logger.error("".join(["Socket connect error! - ", str(PROTO), " ", str(HOST), ":", str(PORT), "\n", str(e)]))
            
    return sock

def validateConfigFile(configFileName: str):
    logger.debug("".join(["Validating config file: '", configFileName, "'"]))

    fo = open(configFileName, "r")
    content = fo.read()
    fo.close()

    configYamlSafeLoad = yaml.safe_load(content)

    # Inputs
    dExpectedInputConfig = {
        "inputs": {
            "global": {
                "host": "target_host_name"
            }
        }
    }
    sExpectedInputsFormat = "".join(["\n", "Expected input: configuration:", "\n", str(json.dumps(dExpectedInputConfig, indent=4))])

    if not "inputs"in configYamlSafeLoad:
        logger.critical("".join(["FATAL: `inputs:` not defined in config file.", sExpectedInputsFormat]))
        exit(1)
    
    if not "global" in configYamlSafeLoad["inputs"]:
        logger.critical("".join(["FATAL: `global:` not defined beneath inputs:", sExpectedInputsFormat]))
        exit(1)
        
    if not "host" in configYamlSafeLoad["inputs"]["global"]:
        logger.critical("".join(["FATAL: `host:` not defined beneath global:", sExpectedInputsFormat]))
        exit(1)

    for log_replay_gl_input in l_valid_event_types:
        if not log_replay_gl_input == "mixed" and not log_replay_gl_input in configYamlSafeLoad["inputs"]:
            logger.critical("".join(["FATAL: event type '", log_replay_gl_input, "' not specified beneath `inputs:` in config file."]))
            exit(1)

    return True

def validateEventFile(eventFileName: str):
    lineNumber = 1
    iInvalidLines = 0
    lInvalidLines = []

    #build events array
    # open specified events file
    with open(eventFileName, "r") as x:
        # for each line
        for t in x:
            bErrorForThisLine = False
            b_ignore_line_when_validating = False
            first_char = t[0]

            # ignore comments
            if first_char == "#":
                b_ignore_line_when_validating = True
            # ignore empty lines
            if first_char == "\n":
                b_ignore_line_when_validating = True

            if b_ignore_line_when_validating == False:
                if not "|" in t:
                    bErrorForThisLine = True
                else:
                    try:
                        test = t.partition("|")

                        # validate data after | exists
                        if len(str(test[2]).strip()) == 0:
                            bErrorForThisLine = True
                        
                        # validate data before | is a float
                        if not type(float(test[0])) is float:
                            bErrorForThisLine = True

                    except:
                        bErrorForThisLine = True
                    
                
                if bErrorForThisLine == True:
                    dInvalidLine = {
                        "lineNumber": lineNumber,
                        "lineString": str(t).strip()
                    }
                    lInvalidLines.append(dInvalidLine)
                
            lineNumber = lineNumber + 1

    if len(lInvalidLines) == 0:
        return True
    
    sPlural = '';
    if len(lInvalidLines) > 1:
        sPlural = 's';

    logger.error("".join(["Found ", str(len(lInvalidLines)), " invalid line", sPlural," in event file '", str(eventFileName),"'.", "\n", json.dumps(lInvalidLines, indent=4)]))    
    return False

def runSendEvents(inputName: str, inputConf: dict, inputsGlobalHost: str|bool):
    # HOST, PORT, PROTO, eventsFile, epsRange
    HOST        = ""

    if not inputsGlobalHost == False:
        HOST    = inputsGlobalHost

    # for ovverride
    if "host" in inputConf:
        HOST    = inputConf["host"]
    
    if not len(HOST):
        logger.error("".join(["'HOST' is not specified '", str(inputName), "'"]))
        return False

    PORT        = inputConf["port"]
    PROTO       = inputConf["protocol"]
    eventsFile  = base_path + "/" + inputConf["events_file"]
    epsRange    = msgPerSecRangeForInput(inputName, inputConf)

    logger.info("".join(["Sending Events - ", inputName, " - ", str(PROTO), " ", str(HOST), ":", str(PORT)]))

    # Send events to host
    if exists(eventsFile):
        # validate event file is valid!
        bEventFileIsVald = validateEventFile(eventsFile)
        if bEventFileIsVald == True:
            sendEvents(HOST, PORT, PROTO, inputName, eventsFile, epsRange)
        else:
            logger.error("".join(["Cannot start send events for event file '", eventsFile, "'"]))
    else:
        logger.error("".join(["Events file '", str(eventsFile), "' does not exist!"]))

def createAssets(tuples, domains):
    for asset in tuples:

        ##### Machine assets
        machine = {}
        machine['name'] = asset[0] + "-dsktp"
        machine['category'] = ["Workstation", "Domain Workstation", "Windows"]
        machine['priority'] = 3
        machine['details'] = {}
        machine['details']['description'] = asset[0] + "'s personal workstation"
        machine['details']['type'] = "machine"
        machine['details']['owner'] = asset[0]
        machine['details']['hostnames'] = [asset[0] + "-dsktp"]
        machine['details']['ip_addresses'] = [asset[1]]
        #record['details']['mac_addresses'] =''
        #record['details']['geo_info']
        #record['details']['geo_info']['city_name']
        #record['details']['geo_info']['region']
        #record['details']['geo_info']['country_name']
        #record['details']['geo_info']['latitude']
        #record['details']['geo_info']['longitude']
        #record['details']['geo_info']['country_iso_code']
        #record['details']['geo_info']['time_zone']

        ##### Users assets
        user = {}
        user['name'] = asset[0]
        user['category'] = ['Domain User', 'User']
        user['priority'] = 3
        user['details'] = {}
        user['details']['type'] = 'user'
        user['details']['usernames'] = [asset[0], 's_' + asset[0]]
        user['details']['user_ids'] = [asset[0], 's_' + asset[0]]
        emails = []
        for domain in domains:
            emails.append(asset[0] + '@' + domain)
        user['details']['email_addresses'] = emails
        #user['details']['first_name'] = asset[0][0:1]
        #user['details']['last_name'] = asset[0][1:]

        doGraylogApi("POST", "/api/plugins/org.graylog.plugins.securityapp.asset/assets", {}, user, 200, True, False)
        doGraylogApi("POST", "/api/plugins/org.graylog.plugins.securityapp.asset/assets", {}, machine, 200, True, False)

l_valid_event_types = ['windows', 'cisco_asa', 'palo_alto', 'watchguard', 'cloudflare', 'mixed', 'fortinet', 'applocker', 'pfsense', 'm365']
l_valid_event_types.sort()

# Parse Arguments
parser = argparse.ArgumentParser()
parser.add_argument('-E', '--event_type', help='The event type to send', default="windows", type=str, choices=l_valid_event_types, required=True)
parser.add_argument("--debug", '-D', help="For debugging", action=argparse.BooleanOptionalAction, default=False)
parser.add_argument("--verbose", '-V', help="Output to console logs that are being sent.", action=argparse.BooleanOptionalAction, default=False)
parser.add_argument("--override-no-verbose", help="Allow disabling verbose when using debug mode", action=argparse.BooleanOptionalAction, default=False)
parser.add_argument("--file", '-F', help='Config file to use. Defaults to config.yml', default="config.yml", type=str, required=False)
parser.add_argument("--overrides", help='Overrides for config file. Useful to apply changes or updates from repo while allowing custom input hosts and timezone', type=str, required=False)
parser.add_argument("--lines", help='Total log messages to send. Useful for testing and debugging.', default=500000000, type=int, required=False)
parser.add_argument("--show-config", help="Export fully parsed config, including overrides", action=argparse.BooleanOptionalAction, default=False)
parser.add_argument("--log", help='Output log file', default="", type=str, required=False)
parser.add_argument("--create-inputs", help="Automatically create required inputs on Graylog node", action=argparse.BooleanOptionalAction, default=False)
parser.add_argument("--wait", help="Wait for graylog API to be reachable.", action=argparse.BooleanOptionalAction, default=False)
parser.add_argument("--create-assets", help="create assets based on config.yml", action=argparse.BooleanOptionalAction, default=False)
parser.add_argument("--console-level", default="INFO")
parser.add_argument("--log-level", default="INFO")

args = parser.parse_args()

logFile = str(args.log)

logger = logging.getLogger('PythonGraylogLogReplay')
logger.setLevel(logging.DEBUG)
console_log_level = args.console_level

bVerbose = args.verbose
if args.debug == True:
    console_log_level = "DEBUG"
    if args.override_no_verbose == False:
        bVerbose = True

strConfigFile = args.file

# ================= BACKOFF START ==============================

# Number of seconds to wait before retrying after a socket error
iSocketRetryWaitSec = 5

# Maximum number of retries to attempt. script exits if max is reach so be careful!
iSocketMaxRetries = 99999

# How many seconds to add before each retry
# backoff resets after a successful connection
iSocketRetryBackOffSec = 10

# maximum allowed retry wait in seconds
iSocketRetryBackOffMaxSec = 300

# how many retries before the backoff time is added before each retry
iSocketRetryBackOffGraceCount = 24

# ================= BACKOFF END ================================

# ================= LOGGING START ==============================

bEnableLogFileOutput = False
if len(args.log) > 0:
    bEnableLogFileOutput = True
    strLogFileName = args.log

# ================= LOGGING END ================================

dictEnableInput = {}
for eventType in l_valid_event_types:
    dictEnableInput[eventType] = True

def log_level_from_string(log_level: str):
    if log_level.upper() == "DEBUG":
        return logging.DEBUG
    elif log_level.upper() == "INFO":
        return logging.INFO
    elif log_level.upper() == "WARN":
        return logging.WARN
    elif log_level.upper() == "ERROR":
        return logging.ERROR
    elif log_level.upper() == "CRITICAL":
        return logging.CRITICAL

    return logging.INFO

# =============================================================================
# Logging handlers
# File Logging
if len(args.log) > 0:
    logging_file_handler = logging.FileHandler(logFile)
    logging_file_handler.setLevel(log_level_from_string(str(args.log_level)))
    formatter = logging.Formatter('%(asctime)s.%(msecs)03d %(levelname)-8s [sendevents.py] %(message)s', '%Y-%m-%d %H:%M:%S')
    logging_file_handler.setFormatter(formatter)
    logger.addHandler(logging_file_handler)

# Console Logging
try:
    logging_console_handler = colorlog.StreamHandler()
    formatter = ColoredFormatter(
            '%(asctime)s.%(msecs)03d %(log_color)s%(levelname)-8s%(reset)s [sendevents.py] %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S',
            reset=True,
            log_colors={
                "DEBUG": "cyan",
                "INFO": "green",
                "WARNING": "yellow",
                "ERROR": "red",
                "CRITICAL": "red",
            },
        )
except:
    logging_console_handler = logging.StreamHandler()
    formatter = logging.Formatter('%(asctime)s.%(msecs)03d %(levelname)-8s %(message)s', '%Y-%m-%d %H:%M:%S')

logging_console_handler.setLevel(log_level_from_string(str(console_log_level)))
logging_console_handler.setFormatter(formatter)
logger.addHandler(logging_console_handler)
# =============================================================================

logger.info("".join(["Starting sendevents.py with config ", str(args)]))

if exists(strConfigFile):
    logger.info("".join(["Using config file: ", str(strConfigFile)]))
    # validate config file, below function will exit(1) script if config file has errors/is invalid
    bConfigFileIsValid = validateConfigFile(strConfigFile)

    with open(strConfigFile, 'r') as stream:
        out = yaml.safe_load(stream)
        getAuthenticationPackageName = out['windows']['AuthenticationPackageName']
        getDomain = out['windows']['DomainShortName']
        getFQDN = out['windows']['Domain']
        getLogonType = out['windows']['LogonType']
        getEndUser = out['windows']['EndUser']
        getWindowsAdmin = out['windows']['WindowsAdmin']
        getWindowsClients= out['windows']['workstations']
        getDC = out['windows']['domainControllers']
        getLocalGroup = out['windows']['localSecGroups']
        getADGroups = out['windows']['domainSecGroups']

        #Applocker
        getApplockerBadApps = out['windows']['applockerBadApps']
        getApplockerGoodApps = out['windows']['applockerGoodApps']


        getCISCOAdmin = out['cisco_asa']['CISCOAdmin']
        getConnectionType = out['cisco_asa']['CISCOConnectionType']
        getACLAction = out['cisco_asa']['CISCOACLAction']
        getACLNames = out['cisco_asa']['CISCOACLNames']

        getAdmin = out['generic']['Admin']
        getDesktopInternalIP = out['generic']['desktopIPRange']

        bAddThisIpToList = True
        for ip in ipaddress.IPv4Network(getDesktopInternalIP[0] + '/26'):
            bAddThisIpToList = True

            if str(ip) == getDesktopInternalIP[0]:
                bAddThisIpToList = False

            if re.match("\.0$", str(ip)):
                bAddThisIpToList = False
            
            if re.match("\.53$", str(ip)):
                bAddThisIpToList = False
            
            if bAddThisIpToList == True:
                getDesktopInternalIP.append(str(ip))
        
        if getDesktopInternalIP[0] in getDesktopInternalIP:
                getDesktopInternalIP.remove(getDesktopInternalIP[0])

        getDMZIP = out['generic']['DMZIP']
        getUntrustIP = out['generic']['UntrustIP']


        getACMEInternalAllowedServicePort = out['firewall_generic']['AllowedPorts']
        getACMEInternalDeniedServicePort = out['firewall_generic']['deniedPorts']
        getHighSourcePort = out['firewall_generic']['HighSourcePort']
        getBadURL = out['firewall_generic']['BadURL']
        getGoodURL = out['firewall_generic']['GoodURL']
        getFWAction = out['firewall_generic']['FWAction']
        getProtocol = out['firewall_generic']['Protocol']
        getAMCEAgentAddress = out['firewall_generic']['AMCEAgentAddress']
        getAMCEFireWallDeviceAddress = out['firewall_generic']['AMCEFireWallDeviceAddress']
        getFORTIGATEHostname = out['firewall_generic']['FORTIGATEHostname']
        getCISCOASAHostName = out['firewall_generic']['CISCOASAHostName']
        getWATCHGUARDHostName = out['firewall_generic']['WATCHGUARDHostName']
        getPublicAddress = out['firewall_generic']['PublicAddress']
        getInterface = out['firewall_generic']['InterfaceName']
        
        inputsDict = out["inputs"]
        inputsGlobalHost = False
        if "global" in inputsDict and type(inputsDict["global"]) is dict and "host" in inputsDict["global"]:
            inputsGlobalHost = inputsDict["global"]["host"]

        #dictWindows = parseHostPortProto(out, "windows")
        strWindowsHost = inputsDict["windows"]["host"]
        strWindowsPort = inputsDict["windows"]["port"]
        strWindowsProtocol = inputsDict["windows"]["protocol"]

        #dictCiscoAsa = parseHostPortProto(out, "cisco_asa")
        strCiscoAsaHost = inputsDict["cisco_asa"]["host"]
        strCiscoAsaPort = inputsDict["cisco_asa"]["port"]
        strCiscoAsaProtocol = inputsDict["cisco_asa"]["protocol"]

        strPaloAltoHost = inputsDict["palo_alto"]["host"]
        strPaloAltoPort = inputsDict["palo_alto"]["port"]
        strPaloAltoProtocol = inputsDict["palo_alto"]["protocol"]

        if "syslog_timezone" in inputsDict:
            strSyslogTimeZone = inputsDict["syslog_timezone"]
        else:
            strSyslogTimeZone = "UTC"
        
        if "syslog_rfc_timestamp_format" in inputsDict:
            strSyslogRfcTimestampFormat = inputsDict["syslog_rfc_timestamp_format"]
        else:
            strSyslogRfcTimestampFormat = "3164"

        # handle reading config for random EPS based on day of week
        # Defaults to disabled
        enableRandomEpsByDayOfWeek = False
        randomEpsByDayOfWeekMultipliers = {"mon": 1, "tue": 1, "wed": 1, "thu": 1, "fri": 1, "sat": 1, "sun": 1}
        if "random_eps_by_day_of_week" in inputsDict:
            if "enabled" in inputsDict["random_eps_by_day_of_week"]:
                enableRandomEpsByDayOfWeek = inputsDict["random_eps_by_day_of_week"]["enabled"]
                
                if enableRandomEpsByDayOfWeek == True:
                    if "multipliers" in inputsDict["random_eps_by_day_of_week"]:
                        randomEpsByDayOfWeekMultipliers = inputsDict["random_eps_by_day_of_week"]["multipliers"]
        else:
            enableRandomEpsByDayOfWeek = False
        
        # read config file for EPS multiplier by hour of day
        # Defaults to disabled
        enableRandomEpsByHourOfDay = False
        epsByHourOfDayMultipliers = {}
        if "random_eps_by_hour_of_day" in inputsDict:
            if "enabled" in inputsDict["random_eps_by_hour_of_day"]:
                enableRandomEpsByHourOfDay = inputsDict["random_eps_by_hour_of_day"]["enabled"]

                if enableRandomEpsByHourOfDay == True:
                    if "multipliers" in inputsDict["random_eps_by_hour_of_day"]:
                        epsByHourOfDayMultipliers = inputsDict["random_eps_by_hour_of_day"]["multipliers"]
        
        else:
            enableRandomEpsByHourOfDay = False
        
        dictGraylogApi = {}
        if "graylog_api" in out:
            for item in out["graylog_api"]:
                dictGraylogApi[item] = out["graylog_api"][item]

        # Build input name/type lookup
        dInputTypeByName = {}
        if "input_types" in out:
            dInputTypeByName = out['input_types']

        # Cloudflare
        listClFlBotScoreSrc = out["cloudflare"]["BotScoreSrc"]
        listClFlCacheCacheStatusValues = out["cloudflare"]["CacheCacheStatus"]['values']
        listClFlCacheCacheStatusWeights = out["cloudflare"]["CacheCacheStatus"]['weights']
        listClFlBadClientIpInfo = out["cloudflare"]["badClientAsnCountryIpIpClass"]
        strClFlClientRequestHost = out["cloudflare"]["clientRequestHost"]
        listClFlClientRequestUserAgentValues = out["cloudflare"]["ClientRequestUserAgent"]['values']
        listClFlClientRequestUserAgentWeights = out["cloudflare"]["ClientRequestUserAgent"]['weights']
        ClFlBotClientReqUserAgt = out["cloudflare"]["BotClientRequestUserAgent"]
        strClFlClientSSLProtocolValues = out["cloudflare"]["ClientSSLProtocol"]['values']
        strClFlClientSSLProtocolWeights = out["cloudflare"]["ClientSSLProtocol"]['weights']
        listClFlClientCiphers = out["cloudflare"]["ClientSSLCiphers"]
        listClFlbadEdgePathingOp = out["cloudflare"]["badEdgePathingOp"]
        strClFlEdgeRequestHostPrefix = out["cloudflare"]["EdgeRequestHostPrefix"]
        listClFlEdgeServerIPPrefix = out["cloudflare"]["EdgeServerIPPrefix"]
        strClFlOriginIPPrefix = out["cloudflare"]["OriginIPPrefix"]
        listClFlEdgeResponseContentType = out["cloudflare"]["EdgeResponseContentType"]
        listClFlClientRequestProtocol = out["cloudflare"]["ClientRequestProtocol"]
        listClFlClientRequestMethod = out["cloudflare"]["ClientRequestMethod"]
        listClFlClientRequestURI = out["cloudflare"]["ClientRequestURI"]
        listClFlEdgeResponseStatus = out["cloudflare"]["EdgeResponseStatus"]

        if "nat_ip_subnet" in out:
            strNatIpCidrSubnet = str(out["nat_ip_subnet"])
        else:
            strNatIpCidrSubnet = ""

        # fortinet

        # DNS
        listDnsQueryAndResponses = out["dnsQueriesAndResponses"]
        listDnsBlockedQueryAndResponses = out["dnsBlockedQueriesAndResponses"]

        # Viruses
        listEmailVirus = out["virus"]["email"]

        # Severity Level
        listSeverityLevelIps = out["severity_level"]["ips"]

else:
    logger.critical("".join(["FATAL: Config file '", str(strConfigFile), "' does not exist!"]))
    exit()

listOverrideDisabledInputs = []
if exists(str(args.overrides)):
    logger.info("".join(["Using overrides file:  '", str(args.overrides), "'"]))

    with open(str(args.overrides), 'r') as stream:
        dictOverrides = yaml.safe_load(stream)
        dictInputsOverrides = dictOverrides["inputs"]

        if "syslog_timezone" in dictInputsOverrides:
            strSyslogTimeZone = dictInputsOverrides["syslog_timezone"]
        
        if "syslog_rfc_timestamp_format" in dictInputsOverrides:
            strSyslogRfcTimestampFormat = dictInputsOverrides["syslog_rfc_timestamp_format"]
        
        if "random_eps_by_day_of_week" in dictInputsOverrides:
            if "enabled" in dictInputsOverrides["random_eps_by_day_of_week"]:
                enableRandomEpsByDayOfWeek = dictInputsOverrides["random_eps_by_day_of_week"]["enabled"]
                if enableRandomEpsByDayOfWeek == True:
                    if "multipliers" in dictInputsOverrides["random_eps_by_day_of_week"]:
                        randomEpsByDayOfWeekMultipliers = dictInputsOverrides["random_eps_by_day_of_week"]["multipliers"]
        
        if "random_eps_by_hour_of_day" in dictInputsOverrides:
            if "enabled" in dictInputsOverrides["random_eps_by_hour_of_day"]:
                enableRandomEpsByHourOfDay = dictInputsOverrides["random_eps_by_hour_of_day"]["enabled"]
                if enableRandomEpsByHourOfDay == True:
                    if "multipliers" in dictInputsOverrides["random_eps_by_hour_of_day"]:
                        epsByHourOfDayMultipliers = dictInputsOverrides["random_eps_by_hour_of_day"]["multipliers"]
        
        if "graylog_api" in dictOverrides:
            for item in dictOverrides["graylog_api"]:
                dictGraylogApi[item] = dictOverrides["graylog_api"][item]

        for inputConf in dictInputsOverrides:
            thisDict = dictInputsOverrides[inputConf]
            if "host" in thisDict or "enabled" in thisDict:
                dOrig = {}
                dReplacements = {}
                dDiff = {}

                inputsDict[inputConf]['overrides'] = {}
                for inputConfigItem in thisDict:
                    if inputConfigItem in inputsDict[inputConf]:
                        dOrig[inputConfigItem] = inputsDict[inputConf][inputConfigItem]
                    else:
                        dOrig[inputConfigItem] = None
                    dReplacements[inputConfigItem] = dictInputsOverrides[inputConf][inputConfigItem]
                    inputsDict[inputConf][inputConfigItem] = dictInputsOverrides[inputConf][inputConfigItem]
                inputsDict[inputConf]['overrides']['originals'] = dOrig
                inputsDict[inputConf]['overrides']['replacments'] = dReplacements

                for replacedItem in inputsDict[inputConf]['overrides']['replacments']:
                    if inputsDict[inputConf]['overrides']['replacments'][replacedItem] != inputsDict[inputConf]['overrides']['originals'][replacedItem]:
                        dDiff[replacedItem] = inputsDict[inputConf]['overrides']['replacments'][replacedItem]
                
                inputsDict[inputConf]['overrides']['diff'] = dDiff

            if "enabled" in thisDict:
                if dictInputsOverrides[inputConf]['enabled'] == False:
                    listOverrideDisabledInputs.append(inputConf)

if args.show_config == True:
    import json
    json_object = json.dumps(inputsDict, indent = 4)
    logger.info(json_object)
    exit()

EPS=2
# If i'm understanding the math correctly this means the script will run continuously for ~15.8 years.
loglines=args.lines

#these need to be moved into the event builder
get4625FailureReason = ["0xC0000064", "0xC000006A", "0xC0000234"]
get4776FailureReason = ["C0000064", "C000006A", "C0000234"]
getDirection = ["inbound", "outbound"]
my_tuples=buildTuples(getEndUser, getDesktopInternalIP)

msft_services = [['Outlook','13.107.6.153'],['SharePoint','13.107.136.1'],['Office365','13.107.6.171'],['Teams','13.107.64.1']]
pubIP = []
for ip in ipaddress.IPv4Network('109.144.0.0/12'):
    pubIP.append(str(ip))

VPN_tuples=buildVPNTuples(getEndUser, pubIP)

lNatIps = generateRandomListOfIpsBasedOnCidrSubnet(strNatIpCidrSubnet)

if args.debug == True:
    logger.debug("DEBUG MODE ENABLED! Will not send any events.")

# Event Types to send
base_path = "Event Files"

# verify if Graylog API config is valid or not so we know if we can send reqs to it.
gBoolIsGraylogApiConfigValid = graylogApiConfigIsValid(False)

def buildInputs(reqInputs):
    for input in reqInputs:
        inputTypeName   = input["input_type"]
        if inputTypeName in dInputTypeByName:
            inputType = dInputTypeByName[inputTypeName]['type']

            PORT = input["port"]
            # inputsDict[varForEventType]["host"], inputsDict[varForEventType]["port"], inputsDict[varForEventType]["protocol"], base_path + "/" + inputsDict[varForEventType]["events_file"], msgPerSecRangeForInput(varForEventType, inputsDict)

            # check if input exists on targeted graylog cluster
            if gBoolIsGraylogApiConfigValid == True:
                bDoesInputExist = doesGraylogInputExist(inputType, PORT)
                if bDoesInputExist == False:
                    if args.debug == False:
                        if args.create_inputs == False:
                            logger.error("".join(["Graylog Input Does not exist for ", str(inputType), "\n", "rerun script using --create-inputs argument to automatically create inputs."]))
                        else:
                            logger.warning("".join(["Input missing for ", str(inputType), ". Will create it."]))
                            bInputCreateSuccess = createGraylogInput(inputType, PORT)
                            if bInputCreateSuccess == True:
                                logger.info("".join(["Input created successfully for ", str(inputType)]))
                            else:
                                logger.error("".join(["Failed to create input for ", str(inputType)]))
                    else:
                        logger.debug("".join(["Debug mode enalbed, skipping input creation for ", str(inputType)]))
                else:
                    logger.info("".join(["Verified that input exists for ", str(inputType)]))

            else:
                logger.error("Graylog Config is invalid")
        else:
            logger.error("".join(["Input ", str(inputTypeName), " not found in `input_types` via `config.yml`. Cannot create this input."]))

def do_wait_until_online():
    logger.info("".join(["--wait argument used. ", "Waiting until graylog cluster is online and reachable..."]))
    iSocketRetries = 0
    iSocketInitialRetryBackOff = iSocketRetryWaitSec

    while iSocketRetries < iSocketMaxRetries:
        if iSocketRetries > 0:
            logger.info("".join(["Retry ", str(iSocketRetries), " of ", str(iSocketMaxRetries)]))

        r = doGraylogApi("GET", "/api/", {}, {}, 200, True, True)
        if 'success' in r:
            if r['success'] == True:
                logger.info("Graylog Cluster is Online")
                return True
        
        logger.error("".join(["Exception: ", str(r["exception"])]))
        logger.info("".join(["Waiting ", str(iSocketInitialRetryBackOff), "s, Max backoff: ", str(iSocketRetryBackOffMaxSec), "s..."]))

        # sleep for X seconds
        time.sleep(iSocketInitialRetryBackOff)

        # Increment socket retry count
        iSocketRetries = iSocketRetries + 1

        # If the number of retries exceeds the intial backoff retry grace count
        #   Don't apply backoff for the first X number of retries in case the error was short lived
        if iSocketRetries > iSocketRetryBackOffGraceCount:
            # if backoff value is less than max, keep adding backoff value to delay
            if iSocketInitialRetryBackOff < iSocketRetryBackOffMaxSec:
                iSocketInitialRetryBackOff = iSocketInitialRetryBackOff + iSocketRetryBackOffSec

            # if backoff value exceeds max, set to max
            if iSocketInitialRetryBackOff > iSocketRetryBackOffMaxSec:
                iSocketInitialRetryBackOff = iSocketRetryBackOffMaxSec

        # If socket retries exceeds max, exit script
        if iSocketRetries > iSocketMaxRetries:
            logger.critical("FATAL: To many socket retries!")
            return False

    return False

# allow disabling inputs directly form config.yml
for inputEnableDisable in inputsDict:
    if "port" in inputsDict[inputEnableDisable]:
        if "enabled" in inputsDict[inputEnableDisable]:
            if inputsDict[inputEnableDisable]["enabled"] == False:
                listOverrideDisabledInputs.append(inputEnableDisable)

# allow disabling inputs to fully customize what data is sent to graylog
# only need to do this when using MIXED
if args.event_type == "mixed":
    for inputOverrideEnableDisable in listOverrideDisabledInputs:
        # accomadated duplicated, only run once
        if inputOverrideEnableDisable in l_valid_event_types:
            l_valid_event_types.remove(inputOverrideEnableDisable)
            logger.debug("".join(["Input '", str(inputOverrideEnableDisable), "' disabled. Not starting."]))

# if input `-E` is a single input, disable all but selected input
if args.event_type != "mixed":
    l_valid_event_types = [args.event_type]

# removed mixed from input list as its not a valid input
# if we specify only a single event, mixed won't be in the list so we can't remove it
if "mixed" in l_valid_event_types:
    l_valid_event_types.remove('mixed')

inputList = []

for log_replay_gl_input in l_valid_event_types:
    inputList.append({'input_type' : inputsDict[log_replay_gl_input]['input_type'], 'port' : inputsDict[log_replay_gl_input]['port']}) 
inputList = [dict(t) for t in {tuple(d.items()) for d in inputList}]

if args.wait == True:
    do_wait_until_online()

# Create Inputs if they do not already exist
buildInputs(inputList)

for log_replay_gl_input in l_valid_event_types:
   Thread(target = runSendEvents, args=(log_replay_gl_input, inputsDict[log_replay_gl_input], inputsGlobalHost)).start()

if args.create_assets == True:
    createAssets(my_tuples, getFQDN)


# misc for testing/debugging
# print(json.dumps(l_valid_event_types, indent = 4))