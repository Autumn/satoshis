require 'sinatra'
require 'open-uri'
require 'sinatra/cross_origin'
require 'json'

set :port, 7654

supported_currencies = open("http://api.coindesk.com/v1/bpi/supported-currencies.json").readlines[0]
$currency_json = JSON.parse(supported_currencies)
$currencies = Hash.new(nil)
$satoshi = 100000000.0

def cache_prices
  $currency_json.each do |currency|
    currency_code = currency["currency"]
    puts "Caching #{currency_code}..."
    $currencies[currency_code] = Hash.new
    $currencies[currency_code]["code"] = currency["currency"]
    $currencies[currency_code]["currency"] = currency["country"]

    url = "https://api.coindesk.com/v1/bpi/currentprice/#{currency_code}.json"
    json = JSON.parse(open(url).readlines[0])

    price = json["bpi"][currency_code]["rate_float"]
    $currencies[currency_code]["rate"] = price.round(2)
    $currencies[currency_code]["satoshis"] = ($satoshi / price).floor
  end
end

puts "Caching prices..."
cache_prices
puts "Done."

get '/' do
  erb :index
end


get '/supported_currencies' do
  $currencies.to_json
end

get '/price/:name' do
  if supported_currencies[params[:name]] != nil
    "#{$currencies[params[:name]]}"
  else
    "error"
  end
end
