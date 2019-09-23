require 'curb'
require 'nokogiri'
require 'csv'

file_name =ARGV[1].strip
category_link = ARGV[0].strip
if category_link[category_link.length - 1] != '/'
    category_link += '/'
end

def parse_product_links(category_link, page = 1)
    product_links = []

    loop do
        if page > 1
            http = Curl.get(category_link + '?p=' + page.to_s)
        else
            http = Curl.get(category_link)
        end

        doc = Nokogiri::HTML(http.body_str)
        doc.xpath("//ul[normalize-space(@id)='product_list']//div[normalize-space(@class)='pro_first_box']/a").each do |e|
            product_links.push(e.attr('href'))
        end
        page += 1

        break if doc.at_xpath("//button[normalize-space(@class)='loadMore next button lnk_view btn btn-default']").nil?
    end

    return product_links
end

def parse_products(product_links)
    products = []

    product_links.each do |product_link|
        product = []
        http = Curl.get(product_link)
        doc = Nokogiri::HTML(http.body_str)
        product_name = doc.xpath("//p[normalize-space(@class)='product_main_name']").text.strip
        doc.xpath("//ul[normalize-space(@class)='attribute_radio_list']/li").each do |e|
            product.push(product_name + ' - ' + e.at_xpath("//span[normalize-space(@class)='radio_label']").text.strip)
            product.push(e.at_xpath("//span[normalize-space(@class)='price_comb']").text.strip)
            product.push(doc.at_xpath("//img[normalize-space(@id)='bigpic']").attr('src').strip)
        end

        products.push(product)
        puts product_link + " DONE"
    end

    return products
end

def write_to_csv(products, file_name)
    CSV.open("#{file_name}.csv", "w") do |csv|
        csv << ["Name", "Price", "Image"]
        products.each do |product|
            csv << product
        end
    end
end

puts "Parsing links to products..."
product_links = parse_product_links(category_link)
puts product_links.count.to_s + " products found"
puts "Parsing all products..."
products = parse_products(product_links)
puts "All products are parsed"
write_to_csv(products, file_name)
puts "Parsed data recorded in #{file_name}.csv"
