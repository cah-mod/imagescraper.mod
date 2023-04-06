SuperStrict

Rem
bbdoc:
End Rem
Module CAH.ImageScraper

Framework BRL.Blitz
Import BRL.Retro
Import CAH.Str
Import Net.libcurl
Import Text.RegEx

Rem
bbdoc: A class that hopefully will help you scrape images from a website.
EndRem
Type TImageScraper Abstract
	
Private
	Global cert:String

Public
	Rem
	bbdoc: Point this to your .pem certificate
	EndRem
	Function SetCertPath(val:String)
		cert = val
	EndFunction
	
	Rem
	bbdoc: Returns a TList of all images found on the website.
	EndRem
	Function Run:TList(url:String, timeout:Long=0)
		Local data:String = Download(url, timeout)
		
		If Not data
			Return Null
		EndIf
		
		Local domain:String = StripURL(url)
		Local protocol:String = GetProtocol(url)
		
		Local list:TList = CreateList()
		
		ParseKnownFileTypes(data, list, "~q", "~q")
		ParseKnownFileTypes(data, list, "'", "'")
		ParseKnownFileTypes(data, list, "(", ")")
		ParseKnownFileTypes(data, list, " ", " ")
		ParseImgTags(data, list)
		
		Local out:TList = CreateList()
		
		For Local image:String = EachIn list
			image = Replace(image, "\u002F", "/")
			
			If StrStartsWith(image, "//")
				image = protocol + ":" + image
			ElseIf StrStartsWith(image, "/")
				image = domain + image
			ElseIf Not StrStartsWith(Lower(image), "http")
				image = TrimRight(url, "/") + "/" + image
			EndIf
			
			If ListContains(out, image)
				Continue
			EndIf
			
			ListAddLast(out, image)
		Next
		
		Return out
	EndFunction
	
Private	
	Function Download:String(url:String, timeout:Long=0)
		Local curl:TCurlEasy = TCurlEasy.Create()
		curl.SetWriteString()
		curl.setOptInt(CURLOPT_FOLLOWLOCATION, 1)
		
		If cert
			curl.setOptString(CURLOPT_CAINFO, cert)
		Else
			curl.setOptInt(CURLOPT_SSL_VERIFYHOST, False)
			curl.setOptInt(CURLOPT_SSL_VERIFYPEER, False)
		EndIf
		
		If timeout
			curl.setOptLong(CURLOPT_CONNECTTIMEOUT_MS, timeout)
			curl.setOptLong(CURLOPT_TIMEOUT_MS, timeout)
		EndIf
		
		curl.setOptString(CURLOPT_URL, url)
		
		'Add some headers to bypass bot detection
		curl.httpHeader(["accept: application/json, text/plain, */*", "Accept-Language: en-US,en;q=0.5", "x-application-type: WebClient", "x-client-version: 2.10.4", "Origin: https://www.googe.com", "user-agent: Mozilla/5.0 (Windows NT 10.0; rv:78.0) Gecko/20100101 Firefox/78.0"])
		
		Local res:Int = curl.perform()
		
		curl.cleanup()
		
		If res
			Return Null
		EndIf
		
		Return curl.ToString()
	EndFunction
	
	Function StripURL:String(url:String)
		Local regex:TRegEx = TRegEx.Create("(?<protocol>\w*)\:\/\/(?:(?:(?<thld>[\w\-]*)(?:\.))?(?<sld>[\w\-]*))\.(?<tld>\w*)(?:\:(?<port>\d*))?")
		
		Local find:TRegExMatch = regex.Find(url)
		
		If Not find
			Return Null
		EndIf
		
		Return find.SubExp()
	EndFunction
	
	Function GetProtocol:String(url:String)
		Local regex:TRegEx = TRegEx.Create("(?<protocol>\w*)\:\/\/(?:(?:(?<thld>[\w\-]*)(?:\.))?(?<sld>[\w\-]*))\.(?<tld>\w*)(?:\:(?<port>\d*))?")
	
		Local find:TRegExMatch = regex.Find(url)
		
		If Not find
			Return Null
		EndIf
		
		Return find.SubExp(1)
	EndFunction
	
	Function ParseKnownFileTypes(data:String, list:TList, encapstart:String, encapend:String)
		Local regex:TRegEx = TRegEx.Create("\" + encapstart + "([a-z0-9/\-\.,:_%\\@\(\)]*\.(jpg|jpeg|png|webp|svg)(?:(\?|#)[a-z,A-Z,0-9&=%]*))\" + encapend)
		
		Local find:TRegExMatch = regex.Find(data)
		
		While find
			Local image:String = find.SubExp(1)
			
			If Not ListContains(list, image)
				ListAddLast(list, image)
			EndIf
			
			find = regex.Find()
		Wend
	EndFunction
	
	Function ParseImgTags(data:String, list:TList)
		Local regex:TRegEx = TRegEx.Create("<img.+?src=[\~q']([a-z0-9/\-\.,:_%\\@\?\=]+)[\~q'].*?>")

		Local find:TRegExMatch = regex.Find(data)

		While find
			Local image:String = find.SubExp(1)
			
			If Not ListContains(list, image)
				ListAddLast(list, image)
			EndIf
			
			find = regex.Find()
		Wend
	EndFunction
EndType