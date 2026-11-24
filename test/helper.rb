# test/helper.rb

require 'fileutils'
require 'minitest/autorun'
require 'minitest/spec'
require 'tmpdir'

require 'data_gov_au'
require 'DataGovAu/ABR'

def fixture_path(name)
  File.join(__dir__, 'fixtures', name)
end

def config_in(directory, **settings)
  DataGovAu::ABR::Config.new(data_directory: directory, **settings)
end

# A package_show result shaped as data.gov.au's, listing the resources given.
def package(resources:)
  {
    'name' => 'abn-bulk-extract',
    'title' => 'ABN Bulk Extract',
    'organization' => {'name' => 'australian-business-register', 'title' => 'Australian Business Register'},
    'license_title' => 'Creative Commons Attribution 3.0 Australia',
    'metadata_modified' => '2026-10-27T21:41:00.366366',
    'resources' => resources,
  }
end

def extract_resource(name, filename, last_modified, size)
  {
    'name' => name,
    'format' => 'ZIP',
    'size' => size,
    'last_modified' => last_modified,
    'url' => "https://data.gov.au/data/dataset/abc/resource/def/download/#{filename}",
  }
end

# A record as the extract writes one now, on a line of its own.
def record_line(abn, status: 'ACT', name: 'A BUSINESS')
  %Q{<ABR recordLastUpdatedDate="20261020" replaced="N"><ABN status="#{status}" ABNStatusFromDate="20261013">#{abn}</ABN><EntityType><EntityTypeInd>PRV</EntityTypeInd></EntityType><MainEntity><NonIndividualName type="MN"><NonIndividualNameText>#{name}</NonIndividualNameText></NonIndividualName></MainEntity><GST status="NON" GSTStatusFromDate="19000101" /></ABR>}
end

# One XML file as the extract writes one now: a header carrying its sequence number and count, lines of padding, the records a line each with a second carriage return after every hundredth, and the close.
def member_text(sequence, records)
  header = %Q{<?xml version="1.0"?><Transfer error="none"><TransferInfo><FileSequenceNumber>#{sequence}</FileSequenceNumber><RecordCount>#{records.length}</RecordCount><ExtractTime>2026-10-28T12:25:33</ExtractTime></TransferInfo>}
  body = records.each_with_index.collect{|record, index| index.zero? ? record : ((index % 100).zero? ? "\r\r\n" : "\r\n") + record}.join
  header + ((' ' * 40) + "\r\n") * 2 + body + "\r\r\n</Transfer>\r\n"
end

# A release held whole as the fetch leaves one: its zips, each holding the files given as name and text, and the catalogue entry they were found through, listing each zip at the length written.
def whole_release(directory, date, zips)
  release = DataGovAu::ABR::Release.new(config_in(directory), date)
  release.create_directory
  zips.each do |zip_name, files|
    Zip::File.open(File.join(release.directory, zip_name), create: true) do |zip|
      files.each{|name, text| zip.get_output_stream(name){|stream| stream.write(text)}}
    end
  end
  release.record_catalogue(package(resources: zips.keys.collect{|zip_name| extract_resource(zip_name, zip_name, '2026-10-27T21:39:23', File.size(File.join(release.directory, zip_name)))}))
  release
end

# Two weeks apart. Between them 22222222222 is cancelled, 25000000000 and 66666666666 appear, 55555555555 goes, and 33333333333, unchanged, moves from the first file to the second as the first fills.
def older_files
  {
    'public_split_1_10.zip' => {'20261028_Public01.xml' => member_text(1, [record_line('11111111111'), record_line('22222222222'), record_line('33333333333')])},
    'public_split_11_20.zip' => {'20261028_Public11.xml' => member_text(11, [record_line('44444444444'), record_line('55555555555')])},
  }
end

def newer_files
  {
    'public_split_1_10.zip' => {'20261104_Public01.xml' => member_text(1, [record_line('11111111111'), record_line('22222222222', status: 'CAN'), record_line('25000000000')])},
    'public_split_11_20.zip' => {'20261104_Public11.xml' => member_text(11, [record_line('33333333333'), record_line('44444444444'), record_line('66666666666')])},
  }
end

def two_releases(directory, older = older_files, newer = newer_files)
  [whole_release(directory, Date.new(2026, 10, 28), older), whole_release(directory, Date.new(2026, 11, 4), newer)]
end
