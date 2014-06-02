require 'open-uri'
require 'nokogiri'
require './lib/exposes_contact_xml'

describe ExposesContactXml do
  it 'exposes the first name' do
    first_name = 'Bob'
    parser = Nokogiri::XML("<ns2:vcard xmlns:ns2=\"urn:ietf:params:xml:ns:vcard-4.0\"><ns2:n><ns2:given>#{first_name}</ns2:given></ns2:n></ns2:vcard>")
    contact = ExposesContactXml.new(parser)
    expect(contact.first_name).to eq first_name
  end
  
  it 'exposes the last name' do
    last_name = 'Bob'
    parser = Nokogiri::XML("<ns2:vcard xmlns:ns2=\"urn:ietf:params:xml:ns:vcard-4.0\"><ns2:n><ns2:surname>#{last_name}</ns2:surname></ns2:n></ns2:vcard>")
    contact = ExposesContactXml.new(parser)
    expect(contact.last_name).to eq last_name
  end

  it 'exposes the middle initial' do
    middle_initial = 'A'
    parser = Nokogiri::XML("<ns2:vcard xmlns:ns2=\"urn:ietf:params:xml:ns:vcard-4.0\"><ns2:n><ns2:additional>#{middle_initial}</ns2:additional></ns2:n></ns2:vcard>")
    contact = ExposesContactXml.new(parser)
    expect(contact.middle_initial).to eq middle_initial
  end

  describe 'prefix' do 
    it 'exposes prefix' do
      prefix = 'Mr'
      parser = Nokogiri::XML("<ns2:vcard xmlns:ns2=\"urn:ietf:params:xml:ns:vcard-4.0\"><ns2:n><ns2:prefix>#{prefix}</ns2:prefix></ns2:n></ns2:vcard>")
      contact = ExposesContactXml.new(parser)
      expect(contact.prefix).to eq prefix  
    end
    it 'is optional' do
      parser = Nokogiri::XML("<ns2:vcard xmlns:ns2=\"urn:ietf:params:xml:ns:vcard-4.0\"><ns2:n><ns2:prefix/></ns2:n></ns2:vcard>")
      contact = ExposesContactXml.new(parser)
      expect(contact.prefix).to eq ''   
    end
  end

  it 'exposes suffix' do
    suffix = 'Jr'
    parser = Nokogiri::XML("<ns2:vcard xmlns:ns2=\"urn:ietf:params:xml:ns:vcard-4.0\"><ns2:n><ns2:suffix>#{suffix}</ns2:suffix></ns2:n></ns2:vcard>")
    contact = ExposesContactXml.new(parser)
    expect(contact.suffix).to eq suffix  
  end

  it 'exposes organization' do
    organization = "Ziltoid's Finest Bean Coffeehouse"
    parser = Nokogiri::XML("<ns2:vcard xmlns:ns2=\"urn:ietf:params:xml:ns:vcard-4.0\"><ns2:org>#{organization}</ns2:org></ns2:vcard>")
    contact = ExposesContactXml.new(parser)
    expect(contact.organization).to eq organization  
  end

  it 'exposes address type' do
    address_type = '1'
    parser = Nokogiri::XML("<ns2:vcard xmlns:ns2=\"urn:ietf:params:xml:ns:vcard-4.0\"><ns2:adr><ns2:parameters><ns2:type><ns2:text>#{address_type}</ns2:text></ns2:type></ns2:parameters></ns2:adr></ns2:vcard>")
    contact = ExposesContactXml.new(parser)
    expect(contact.address_type).to eq address_type    
  end

  it 'exposes street' do
    street1 = '1'
    street2 = '2'

    parser = Nokogiri::XML("<ns2:vcard xmlns:ns2=\"urn:ietf:params:xml:ns:vcard-4.0\"><ns2:adr><ns2:street>#{street1}</ns2:street><ns2:street>#{street2}</ns2:street></ns2:adr></ns2:vcard>")
    contact = ExposesContactXml.new(parser)
    expect(contact.street1).to eq street1
    expect(contact.street2).to eq street2 
  end

  it 'exposes city' do
    city = 'Washington'
    parser = Nokogiri::XML("<ns2:vcard xmlns:ns2=\"urn:ietf:params:xml:ns:vcard-4.0\"><ns2:adr><ns2:locality>#{city}</ns2:locality></ns2:adr></ns2:vcard>")
    contact = ExposesContactXml.new(parser)
    expect(contact.city).to eq city  
  end

  it 'exposes state' do
    state = 'DC'
    parser = Nokogiri::XML("<ns2:vcard xmlns:ns2=\"urn:ietf:params:xml:ns:vcard-4.0\"><ns2:adr><ns2:region>#{state}</ns2:region></ns2:adr></ns2:vcard>")
    contact = ExposesContactXml.new(parser)
    expect(contact.state).to eq state  
  end

  it 'exposes zip' do
    zip = '20002'
    parser = Nokogiri::XML("<ns2:vcard xmlns:ns2=\"urn:ietf:params:xml:ns:vcard-4.0\"><ns2:adr><ns2:code>#{zip}</ns2:code></ns2:adr></ns2:vcard>")
    contact = ExposesContactXml.new(parser)
    expect(contact.zip).to eq zip  
  end

  it 'exposes telephone type' do
    phone_type = 'WORK'
    parser = Nokogiri::XML("<ns2:vcard xmlns:ns2=\"urn:ietf:params:xml:ns:vcard-4.0\"><ns2:tel><ns2:parameters><ns2:type><ns2:text>#{phone_type}</ns2:text></ns2:type></ns2:parameters></ns2:tel></ns2:vcard>")
    contact = ExposesContactXml.new(parser)
    expect(contact.phone_type).to eq phone_type  
  end

  it 'exposes telephone number' do
    phone_number = '111-111-1111'
    parser = Nokogiri::XML("<ns2:vcard xmlns:ns2=\"urn:ietf:params:xml:ns:vcard-4.0\"><ns2:tel><ns2:uri>#{phone_number}</ns2:uri></ns2:tel></ns2:vcard>")
    contact = ExposesContactXml.new(parser)
    expect(contact.phone_number).to eq phone_number  
  end

end