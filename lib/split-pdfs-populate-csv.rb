require 'fileutils'
require 'pdf-reader'
require 'vips'

csv_file    = './src/records.csv'
pdf_dir     = './src/pdfs/'
data_dir    = './src/data/'
pdfs        = Dir.glob("#{pdf_dir}*.pdf")
pdfs_count  = pdfs.length

# write start of csv
File.open(csv_file, 'w') do |file| 
  file.puts("id,label,a_number,parent_pdf_id,redacted,extracted_text")
end

FileUtils.mkdir_p data_dir

# process data
data = pdfs.each_with_index do |path, i|
  GC.start
  reader            = PDF::Reader.new(path)
  parent_page_count = reader.page_count
  parent_pdf_id     = path.sub(pdf_dir, '').sub('.pdf', '')
  redacted          = parent_pdf_id.include? 'redacted'
  a_number          = parent_pdf_id.sub('_redacted', '').sub('_withdrawal', '')

  (0..parent_page_count - 1).each do |index|
    page_num  = index.to_s.rjust(4, "0")
    id        = "#{parent_pdf_id}_#{page_num}"
    target    = "#{data_dir}#{id}.jpg"
    text      = reader.pages[index].text.to_s.gsub(/\R+/, "|").gsub('"', "'")
    data      = [id,id,a_number,parent_pdf_id,redacted,"\"#{text}\""]

    File.open(csv_file, "a") { |file| file.puts data.join(',') }
    
    # return if File.exist? target

    img     = Vips::Image.pdfload path, page: index, n: 1, dpi: 300
    img.jpegsave target
    
    print "writing #{File.basename target} page #{index} / #{parent_page_count}\r"
    $stdout.flush
  end
  
  puts "finished pdf #{i+1}/#{pdfs_count} — process is #{(i.to_f / pdfs_count.to_f * 100.0).round(1)}% complete    \n"
end
