require 'test_helper'

class AllergyImporterTest < ActiveSupport::TestCase
  def test_allergy_importing
    doc = Nokogiri::XML(File.new('test/fixtures/NISTExampleC32.xml'))
    doc.root.add_namespace_definition('cda', 'urn:hl7-org:v3')
    pi = QME::Importer::PatientImporter.instance
    patient = pi.create_c32_hash(doc)
    
    allergy = patient[:allergies][0]
    
    assert_equal '247472004', allergy.reaction['code']

    allergy = patient[:allergies][2]
    assert_equal '73879007', allergy.reaction['code']
    assert_equal '6736007', allergy.severity['code']

  end
end