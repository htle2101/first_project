ENV.each do |k, v|
  env k.to_sym, v
end

every "15 * * * *" do
 rake "-s transbc:google_clear"
end

every "25 * * * *" do
 rake "-s 'transbc:google_clear[auth2]'"
end

every 15.minutes do
 rake "-s transbc:batch_translation"
end

#every "35 * * * *" do
 #rake "-s transbc:batch_translation"
#end

every 1.day, :at => '4:30 am' do
  rake "-s sitemap:refresh"
end

every '0 5 * * *' do
  rake "-s order:confirm_deliver"
end

every 1.day, :at => '0:10 am' do
  rake "-s promo:check_promotion"
end

every 14.days, :at => '6:00 am' do
  rake "-s taobao:import_failed_prop"
end

every 1.day, :at => '3:00 am' do
  rake "-s tag:update_tag_crawl_list"
end

#For Spring Festival
#every 120.hours do
#  rake "pp:update_pp_logistic"
#end

every 1.day, :at => '4:00 am' do
  rake "-s pp:update_pp_logistic"
end

every 1.day, :at => '1:00 am' do
  rake "-s topic:check_products"
end
#every 14.days, :at => '6:00 am' do
  #rake "-s category:update_category_and_prop"
#end
