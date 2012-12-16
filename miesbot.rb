# encoding: utf-8
# Tämä ohjelma etsii Amppareista Mies-tekstejä, katsoo alkuperäisestä lähteestä "Mies .... " -lauseen ja julkaisee sen Twitterissä tilillä @MiehenElämää

# -----------------------------------------------------------------------------------------------------------
# Tämä ohjelma on lisensoitu AGPLv3 -lisenssillä. Lisenssi täällä: http://www.gnu.org/licenses/agpl-3.0.html
# Ohjelmaa saa käyttää melko vapaasti, kunhan uudet versiot lähdekoodista jaetaan samalla lisenssillä.
# Miesbotin tekijä on Esa Mäkinen, sähköposti esa.makinen@iki.fi, twitter @esamakinen
# ----------------------------------------------------------------------------------------------------------

# Lataa tarvittavat kirjastot

require 'rubygems'
require 'twitter'   # Yhteydenpitoon Twitterin kanssa
require 'mechanize' # HTML:n hakuun
require 'json'      # Bitly:n vastauksen käsittelyyn'

# Alusta muuttujat
ok = false
i=0

# Miehen elämää etsivä silmukka alkaa tästä

	while ok == false do

		# Hae Amppareista uusin Mies -teksti
		# Mechanizen ohje: http://mechanize.rubyforge.org/GUIDE_rdoc.html

		agent = Mechanize.new
		page = agent.get('http://www.ampparit.com/haku?q=mies&t=news')

		puts page.links_with(:dom_class => "news-item-headline")[i].text 
		linkki = page.links_with(:dom_class => "news-item-headline")[i].href 

		# Käytä tätä, jos tarttee testata jotain
		# linkki = 'http://www.iltalehti.fi/uutiset/2012100716169190_uu.shtml'
		
		# Hae alkuperäislähde 
		agent2 = Mechanize.new
		page2 = agent2.get(linkki)
		page2_sisalto = page2.parser.xpath('//body').to_html
		
		# Tämä osuus putsaa sisällöstä epäolennaisuuksia
		
		# Etelä-saimaa-korjaus
		page2_sisalto = page2_sisalto.gsub(/(news-list).{1,}(<\/a>)/m,'')
		
		# Seinäjoen sanomat -korjaus
		page2_sisalto = page2_sisalto.gsub(/(region region).{1,}(region region)/m,'')
				
		# Iltalehden uutislista pois
		page2_sisalto = page2_sisalto.gsub(/<div id="tuoreimmat">.{1,}<div class="vaakaviiva">/m,'')
	
				
		# HTML pois
		page2_sisalto = page2_sisalto.gsub(/<.{1,}?>/m,'')

		# Javascript pois
		page2_sisalto = page2_sisalto.gsub(/<script.{1,}<\/script>/m,'')
		
		# Etsi alkuperäislähteestä mies-lause, ja tee siitä twitter-yhteensopiva
		page2_sisalto =  page2_sisalto.match(/[Mm]ies\s.{1,110}[.]/)
		lause = page2_sisalto.to_s

		# Tarkista, että mies-lause on hyvä, ja että mies ei raiskaa, tapa tai kuole
		puts lause
		
		if lause.length == 0 || lause.match(/tappoi/) != nil || lause.match(/raiskasi/) != nil || lause.match(/kuoli/) != nil then 
		i=i+1
		puts 'lause ei kelpaa'
		else
		
		lause = lause.slice(0,1).capitalize + lause.slice(1..-1) 
		ok = true
		end
		
	# Miehen elämää etsivä silmukka päättyy tähän
	end	

	# Lyhennä alkuperäinen linkki Bitlyn lyhentimellä
		# Tarvitset API-keyn ja Usernamen tähän
		hakija = Mechanize.new
		haettava_stringi = String.new

		haettava_stringi = 'http://api.bitly.com/v3/shorten?login=<BITLYN USERNAME TÄHÄN>&apiKey=<BITLYN API KEY TÄHÄN>&longUrl='+linkki+'&format=json'

		bitlyn_sisalto = hakija.get(haettava_stringi)
		lyhytlinkki = JSON.parse(bitlyn_sisalto.content)  # Parsettaa JSON..content, koska Mechanize ei tunne tiedostomuotoa
		
		paivitys = lause+' '+lyhytlinkki["data"]["url"]
		puts paivitys
	


# Twiittaa @miesbot
# Tarvitset Twitteriltä Access tokenin, access token secretin, Consumer keyn ja Consumer secretin. Ne saa rekisteröitymällä developeriksi

Twitter.configure do |config|
  config.consumer_key = "CONSUMER KEY"
  config.consumer_secret = "CONSUMER SECRET"
  config.oauth_token = "ACCESS TOKEN"
  config.oauth_token_secret = "ACCESS TOKEN SECRET"
end

 Twitter.update(paivitys)

