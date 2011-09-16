module Importer
  # TODO Extract Discharge Disposition
  class EncounterImporter < QME::Importer::SectionImporter
    include CoreImporter
    
    def initialize
      @entry_xpath = "//cda:section[cda:templateId/@root='2.16.840.1.113883.3.88.11.83.127']/cda:entry/cda:encounter"
      @code_xpath = "./cda:code"
      @status_xpath = "./cda:statusCode"
      @description_xpath = "./cda:code/cda:originalText/cda:reference[@value] | ./cda:text/cda:reference[@value] "
      @check_for_usable = true               # Pilot tools will set this to false
      @id_map = {}
    end
    
    # Traverses that HITSP C32 document passed in using XPath and creates an Array of Entry
    # objects based on what it finds                          
    # @param [Nokogiri::XML::Document] doc It is expected that the root node of this document
    #        will have the "cda" namespace registered to "urn:hl7-org:v3"
    #        measure definition
    # @return [Array] will be a list of Entry objects
    def create_entries(doc,id_map = {})
      @id_map = id_map
      encounter_list = []
      entry_elements = doc.xpath(@entry_xpath)
      entry_elements.each do |entry_element|
        encounter = Encounter.new
        extract_codes(entry_element, encounter)
        extract_dates(entry_element, encounter)
        extract_description(entry_element, encounter, id_map)
        if @check_for_usable
          encounter_list << encounter if encounter.usable?
        else
          encounter_list << encounter
        end
        extract_performer(entry_element, encounter)
        extract_facility(entry_element, encounter)
        extract_reason(entry_element, encounter)
        extract_admission(entry_element, encounter)
      end
      encounter_list
    end
    
    private
    
    def extract_performer(parent_element, encounter)
      performer_element = parent_element.at_xpath("./cda:performer")
      encounter.performer = import_actor(performer_element) if performer_element
    end

    def extract_facility(parent_element, encounter)
      participant_element = parent_element.at_xpath("./cda:participant[@typeCode='LOC']/cda:participantRole[@classCode='SDLOC']")
      encounter.facility = {}
      if (participant_element)
        encounter.facility['organizationName'] = participant_element.at_xpath("./cda:playingEntity/cda:name").try(:text)
        addresses = participant_element.xpath("./cda:addr").try(:map) {|ae| import_address(ae)}
        encounter.facility['addresses'] = addresses
        telecoms = participant_element.xpath("./cda:telecom").try(:map) {|te| import_telecom(te)}
        encounter.facility['telcoms'] = telecoms
      end
    end
    
    def extract_reason(parent_element, encounter)
      reason_element = parent_element.at_xpath("./cda:entryRelationship[@typeCode='RSON']/cda:act")
      if reason_element
        reason = QME::Importer::Entry.new
        extract_codes(reason_element, reason)
        extract_description(reason_element, reason, @id_map)
        extract_status(reason_element, reason)
        extract_dates(reason_element, reason)
        encounter.reason = reason
      end
    end
    
    def extract_admission(parent_element, encounter)
      encounter.admit_type = extract_code(parent_element, "./cda:priorityCode")
    end
  end
end