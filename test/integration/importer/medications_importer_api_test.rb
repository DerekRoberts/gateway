require 'test_helper'

class MedicationsImporterApiTest < ImporterApiTest
  def test_medications_importing
    assert @context.eval('patient.medications().match({"RxNorm": ["307782"]}).length != 0')
    assert_equal 2, @context.eval('patient.medications()[0].dose().value()')
    assert_equal nil, @context.eval('patient.medications()[0].dose().unit()')
    assert_equal 2005, @context.eval('patient.medications()[0].timeStamp().getUTCFullYear()')
    assert_equal 0, @context.eval('patient.medications()[0].timeStamp().getUTCMonth()')
    assert_equal 1, @context.eval('patient.medications()[0].timeStamp().getUTCDate()')
    assert_equal 6, @context.eval('patient.medications()[0].administrationTiming().period().value()')
    assert_equal 'h', @context.eval('patient.medications()[0].administrationTiming().period().unit()')
    assert_equal nil, @context.eval('patient.medications()[0].administrationTiming().institutionSpecified()')
    assert_equal '73639000', @context.eval('patient.medications()[0].typeOfMedication().code()')
    assert_equal 'SNOMED-CT', @context.eval('patient.medications()[0].typeOfMedication().codeSystemName()')
    assert_equal true, @context.eval('patient.medications()[0].typeOfMedication().isPrescription()')
    assert_equal false, @context.eval('patient.medications()[0].typeOfMedication().isOverTheCounter()')
    assert_equal 'IPINHL', @context.eval('patient.medications()[0].route().code()')
    assert_equal 'Unknown', @context.eval('patient.medications()[0].route().codeSystemName()')
    assert_equal '127945006', @context.eval('patient.medications()[0].site().code()')
    assert_equal 'SNOMED-CT', @context.eval('patient.medications()[0].site().codeSystemName()')
    assert_equal '415215001', @context.eval('patient.medications()[0].productForm().code()')
    assert_equal 'NCI Thesaurus', @context.eval('patient.medications()[0].productForm().codeSystemName()')
    assert_equal 'DrugVehicleCode', @context.eval('patient.medications()[0].vehicle().code()')
    assert_equal 'SNOMED-CT', @context.eval('patient.medications()[0].vehicle().codeSystemName()')
    assert_equal '334980009', @context.eval('patient.medications()[0].deliveryMethod().code()')
    assert_equal 'SNOMED-CT', @context.eval('patient.medications()[0].deliveryMethod().codeSystemName()')
    assert_equal 5, @context.eval('patient.medications()[0].doseRestriction().numerator().value()')
    assert_equal nil, @context.eval('patient.medications()[0].doseRestriction().numerator().unit()')
    assert_equal 10, @context.eval('patient.medications()[0].doseRestriction().denominator().value()')
    assert_equal nil, @context.eval('patient.medications()[0].doseRestriction().denominator().unit()')
    assert_equal 1, @context.eval('patient.medications()[0].fulfillmentHistory().length')
    assert_equal "eleventeen", @context.eval('patient.medications()[0].fulfillmentHistory()[0].prescriptionNumber()')
    assert_equal 2011, @context.eval('patient.medications()[0].fulfillmentHistory()[0].dispenseDate().getUTCFullYear()')
    assert_equal 8, @context.eval('patient.medications()[0].fulfillmentHistory()[0].dispenseDate().getUTCMonth()')
    assert_equal 20, @context.eval('patient.medications()[0].fulfillmentHistory()[0].dispenseDate().getUTCDate()')
    assert_equal 30, @context.eval('patient.medications()[0].fulfillmentHistory()[0].quantityDispensed().value()')
    assert_equal nil, @context.eval('patient.medications()[0].fulfillmentHistory()[0].quantityDispensed().unit()')
    assert_equal 4, @context.eval('patient.medications()[0].fulfillmentHistory()[0].fillNumber()')
  end
end


class E2EMedicationsImporterApiTest < E2EImporterApiTest
  def test_e2e_medications_importing
    assert_equal 9, @context.eval('e2e_patient.medications().length')
    assert @context.eval('e2e_patient.medications().match({"HC-DIN": ["00559407"]})')
    assert @context.eval('e2e_patient.medications().match({"whoATC": ["N02BE01"]}).length != 0')
    #assert_equal "xyz", @context.eval('e2e_patient.medications()')
    #assert_equal 2, @context.eval('e2e_patient.medications()[0].dose().value()')
    #assert_equal nil, @context.eval('e2e_patient.medications()[0].dose().unit()')

    #1st
    assert_equal true, @context.eval('e2e_patient.medications()[0].includesCodeFrom({"HC-DIN": ["00559407"]})')
    assert_equal true, @context.eval('e2e_patient.medications()[0].includesCodeFrom({"whoATC": ["N02BE01"]})')
    assert_equal ' E2E_PRN_FLAG E2E_LONG_TERM_FLAG', @context.eval('e2e_patient.medications()[0].freeTextSig()')
    # test importing of medication strengths
    assert_equal 1, @context.eval('e2e_patient.medications()[0].values().length')
    assert_equal 500, @context.eval('e2e_patient.medications()[0].values()[0].scalar()')
    assert_equal 'MG', @context.eval('e2e_patient.medications()[0].values()[0].units()')

    assert_equal 'active', @context.eval('e2e_patient.medications()[0]["json"]["statusOfMedication"]["value"]')

    assert_equal 2013, @context.eval('e2e_patient.medications()[0].timeStamp().getUTCFullYear()')
    assert_equal 8, @context.eval('e2e_patient.medications()[0].timeStamp().getUTCMonth()')
    assert_equal 27, @context.eval('e2e_patient.medications()[0].timeStamp().getUTCDate()')
    #TODO Provide patientapi with a frequency method
    assert_equal 4, @context.eval('e2e_patient.medications()[0].administrationTiming()["json"]["frequency"]["numerator"]["value"]')
    assert_equal nil, @context.eval('e2e_patient.medications()[0].administrationTiming()["json"]["frequency"]["numerator"]["unit"]')
    assert_equal 1, @context.eval('e2e_patient.medications()[0].administrationTiming()["json"]["frequency"]["denominator"]["value"]')
    assert_equal "d", @context.eval('e2e_patient.medications()[0].administrationTiming()["json"]["frequency"]["denominator"]["unit"]')
    assert_equal nil, @context.eval('e2e_patient.medications()[0].administrationTiming().institutionSpecified()')
    #TODO Determine why the code, codeSystemName, isPrescription, etc. are not available for E2E
    assert_equal nil, @context.eval('e2e_patient.medications()[0].typeOfMedication().code()')
    assert_equal nil, @context.eval('e2e_patient.medications()[0].typeOfMedication().codeSystemName()')
    assert_equal false, @context.eval('e2e_patient.medications()[0].typeOfMedication().isPrescription()')
    assert_equal false, @context.eval('e2e_patient.medications()[0].typeOfMedication().isOverTheCounter()')
    #TODO Determine whether any of route, site, productForm, vehicle, deliveryMethod,
    #TODO doseRestriction, or fulfillmentHistory can be supported
    assert_equal 1, @context.eval('e2e_patient.medications()[0].orderInformation().length')
    assert_equal 'qbGJGxVjhsCx/JR42Bd7tX4nbBYNgR/TehN7gQ==', @context.eval('e2e_patient.medications()[0].orderInformation()[0]["json"]["performer"]["family_name"]')
    assert_equal '', @context.eval('e2e_patient.medications()[0].orderInformation()[0]["json"]["performer"]["given_name"]')
    assert_equal '', @context.eval('e2e_patient.medications()[0].orderInformation()[0]["json"]["performer"]["npi"]')
    assert_equal Time.gm(2013,9,27).to_i, @context.eval('e2e_patient.medications()[0].orderInformation()[0].orderDateTime()').to_i

    #2nd
    assert_equal true, @context.eval('e2e_patient.medications()[1].includesCodeFrom({"HC-DIN": ["00613215"]})')
    assert_equal true, @context.eval('e2e_patient.medications()[1].includesCodeFrom({"whoATC": ["C03DA01"]})')
    assert_equal ' E2E_LONG_TERM_FLAG', @context.eval('e2e_patient.medications()[1].freeTextSig()')
    assert_equal 1, @context.eval('e2e_patient.medications()[1].values().length')
    assert_equal 25.0, @context.eval('e2e_patient.medications()[1].values()[0].scalar()')
    assert_equal 'MG', @context.eval('e2e_patient.medications()[1].values()[0].units()')
    assert_equal 'active', @context.eval('e2e_patient.medications()[1]["json"]["statusOfMedication"]["value"]')
    assert_equal 2013, @context.eval('e2e_patient.medications()[1].timeStamp().getUTCFullYear()')
    assert_equal 8, @context.eval('e2e_patient.medications()[1].timeStamp().getUTCMonth()')
    assert_equal 27, @context.eval('e2e_patient.medications()[1].timeStamp().getUTCDate()')
    assert_equal 1, @context.eval('e2e_patient.medications()[1].orderInformation().length')
    assert_equal 'qbGJGxVjhsCx/JR42Bd7tX4nbBYNgR/TehN7gQ==', @context.eval('e2e_patient.medications()[1].orderInformation()[0]["json"]["performer"]["family_name"]')
    assert_equal '', @context.eval('e2e_patient.medications()[1].orderInformation()[0]["json"]["performer"]["given_name"]')
    assert_equal '', @context.eval('e2e_patient.medications()[1].orderInformation()[0]["json"]["performer"]["npi"]')
    assert_equal Time.gm(2013,9,27).to_i, @context.eval('e2e_patient.medications()[1].orderInformation()[0].orderDateTime()').to_i

    #3rd
    assert_equal true, @context.eval('e2e_patient.medications()[2].includesCodeFrom({"HC-DIN": ["00636533"]})')
    assert_equal true, @context.eval('e2e_patient.medications()[2].includesCodeFrom({"whoATC": ["M01AE01"]})')
    assert_equal ' E2E_PRN_FLAG E2E_LONG_TERM_FLAG', @context.eval('e2e_patient.medications()[2].freeTextSig()')
    assert_equal 1, @context.eval('e2e_patient.medications()[2].values().length')
    assert_equal 400.0, @context.eval('e2e_patient.medications()[2].values()[0].scalar()')
    assert_equal 'MG', @context.eval('e2e_patient.medications()[2].values()[0].units()')
    assert_equal 'active', @context.eval('e2e_patient.medications()[2]["json"]["statusOfMedication"]["value"]')
    assert_equal 2013, @context.eval('e2e_patient.medications()[2].timeStamp().getUTCFullYear()')
    assert_equal 8, @context.eval('e2e_patient.medications()[2].timeStamp().getUTCMonth()')
    assert_equal 27, @context.eval('e2e_patient.medications()[2].timeStamp().getUTCDate()')
    assert_equal 1, @context.eval('e2e_patient.medications()[2].orderInformation().length')
    assert_equal 'qbGJGxVjhsCx/JR42Bd7tX4nbBYNgR/TehN7gQ==', @context.eval('e2e_patient.medications()[2].orderInformation()[0]["json"]["performer"]["family_name"]')
    assert_equal '', @context.eval('e2e_patient.medications()[2].orderInformation()[0]["json"]["performer"]["given_name"]')
    assert_equal '', @context.eval('e2e_patient.medications()[2].orderInformation()[0]["json"]["performer"]["npi"]')
    assert_equal Time.gm(2013,9,27).to_i, @context.eval('e2e_patient.medications()[2].orderInformation()[0].orderDateTime()').to_i

    #4th
    assert_equal true, @context.eval('e2e_patient.medications()[3].includesCodeFrom({"HC-DIN": ["02041421"]})')
    assert_equal true, @context.eval('e2e_patient.medications()[3].includesCodeFrom({"whoATC": ["N05BA06"]})')
    assert_equal ' E2E_PRN_FLAG E2E_LONG_TERM_FLAG', @context.eval('e2e_patient.medications()[3].freeTextSig()')
    assert_equal 1, @context.eval('e2e_patient.medications()[3].values().length')
    assert_equal 1.0, @context.eval('e2e_patient.medications()[3].values()[0].scalar()')
    assert_equal 'MG', @context.eval('e2e_patient.medications()[3].values()[0].units()')
    assert_equal 'active', @context.eval('e2e_patient.medications()[3]["json"]["statusOfMedication"]["value"]')
    assert_equal 2013, @context.eval('e2e_patient.medications()[3].timeStamp().getUTCFullYear()')
    assert_equal 8, @context.eval('e2e_patient.medications()[3].timeStamp().getUTCMonth()')
    assert_equal 27, @context.eval('e2e_patient.medications()[3].timeStamp().getUTCDate()')
    assert_equal 1, @context.eval('e2e_patient.medications()[3].orderInformation().length')
    assert_equal 'qbGJGxVjhsCx/JR42Bd7tX4nbBYNgR/TehN7gQ==', @context.eval('e2e_patient.medications()[3].orderInformation()[0]["json"]["performer"]["family_name"]')
    assert_equal '', @context.eval('e2e_patient.medications()[3].orderInformation()[0]["json"]["performer"]["given_name"]')
    assert_equal '', @context.eval('e2e_patient.medications()[3].orderInformation()[0]["json"]["performer"]["npi"]')
    assert_equal Time.gm(2013,9,27).to_i, @context.eval('e2e_patient.medications()[3].orderInformation()[0].orderDateTime()').to_i

    #5th
    assert_equal true, @context.eval('e2e_patient.medications()[4].includesCodeFrom({"HC-DIN": ["02244993"]})')
    assert_equal true, @context.eval('e2e_patient.medications()[4].includesCodeFrom({"whoATC": ["B01AC06"]})')
    assert_equal ' E2E_LONG_TERM_FLAG', @context.eval('e2e_patient.medications()[4].freeTextSig()')
    assert_equal 1, @context.eval('e2e_patient.medications()[4].values().length')
    assert_equal 81.0, @context.eval('e2e_patient.medications()[4].values()[0].scalar()')
    assert_equal 'MG', @context.eval('e2e_patient.medications()[4].values()[0].units()')
    assert_equal 'active', @context.eval('e2e_patient.medications()[4]["json"]["statusOfMedication"]["value"]')
    assert_equal 2013, @context.eval('e2e_patient.medications()[4].timeStamp().getUTCFullYear()')
    assert_equal 8, @context.eval('e2e_patient.medications()[4].timeStamp().getUTCMonth()')
    assert_equal 27, @context.eval('e2e_patient.medications()[4].timeStamp().getUTCDate()')
    assert_equal 1, @context.eval('e2e_patient.medications()[4].orderInformation().length')
    assert_equal 'qbGJGxVjhsCx/JR42Bd7tX4nbBYNgR/TehN7gQ==', @context.eval('e2e_patient.medications()[4].orderInformation()[0]["json"]["performer"]["family_name"]')
    assert_equal '', @context.eval('e2e_patient.medications()[4].orderInformation()[0]["json"]["performer"]["given_name"]')
    assert_equal '', @context.eval('e2e_patient.medications()[4].orderInformation()[0]["json"]["performer"]["npi"]')
    assert_equal Time.gm(2013,9,27).to_i, @context.eval('e2e_patient.medications()[4].orderInformation()[0].orderDateTime()').to_i

    #6th
    assert_equal true, @context.eval('e2e_patient.medications()[5].includesCodeFrom({"HC-DIN": ["02351420"]})')
    assert_equal true, @context.eval('e2e_patient.medications()[5].includesCodeFrom({"whoATC": ["C03CA01"]})')
    assert_equal ' E2E_LONG_TERM_FLAG', @context.eval('e2e_patient.medications()[5].freeTextSig()')
    assert_equal 1, @context.eval('e2e_patient.medications()[5].values().length')
    assert_equal 20.0, @context.eval('e2e_patient.medications()[5].values()[0].scalar()')
    assert_equal 'MG', @context.eval('e2e_patient.medications()[5].values()[0].units()')
    assert_equal 'active', @context.eval('e2e_patient.medications()[5]["json"]["statusOfMedication"]["value"]')
    assert_equal 2013, @context.eval('e2e_patient.medications()[5].timeStamp().getUTCFullYear()')
    assert_equal 8, @context.eval('e2e_patient.medications()[5].timeStamp().getUTCMonth()')
    assert_equal 27, @context.eval('e2e_patient.medications()[5].timeStamp().getUTCDate()')
    assert_equal 1, @context.eval('e2e_patient.medications()[5].orderInformation().length')
    assert_equal 'qbGJGxVjhsCx/JR42Bd7tX4nbBYNgR/TehN7gQ==', @context.eval('e2e_patient.medications()[5].orderInformation()[0]["json"]["performer"]["family_name"]')
    assert_equal '', @context.eval('e2e_patient.medications()[5].orderInformation()[0]["json"]["performer"]["given_name"]')
    assert_equal '', @context.eval('e2e_patient.medications()[5].orderInformation()[0]["json"]["performer"]["npi"]')
    assert_equal Time.gm(2013,9,27).to_i, @context.eval('e2e_patient.medications()[5].orderInformation()[0].orderDateTime()').to_i

    #7th
    assert_equal true, @context.eval('e2e_patient.medications()[6].includesCodeFrom({"HC-DIN": ["02363283"]})')
    assert_equal true, @context.eval('e2e_patient.medications()[6].includesCodeFrom({"whoATC": ["C09AA05"]})')
    assert_equal ' E2E_LONG_TERM_FLAG', @context.eval('e2e_patient.medications()[6].freeTextSig()')
    assert_equal 1, @context.eval('e2e_patient.medications()[6].values().length')
    assert_equal 5.0, @context.eval('e2e_patient.medications()[6].values()[0].scalar()')
    assert_equal 'MG', @context.eval('e2e_patient.medications()[6].values()[0].units()')
    assert_equal 'active', @context.eval('e2e_patient.medications()[6]["json"]["statusOfMedication"]["value"]')
    assert_equal 2013, @context.eval('e2e_patient.medications()[6].timeStamp().getUTCFullYear()')
    assert_equal 8, @context.eval('e2e_patient.medications()[6].timeStamp().getUTCMonth()')
    assert_equal 27, @context.eval('e2e_patient.medications()[6].timeStamp().getUTCDate()')
    assert_equal 1, @context.eval('e2e_patient.medications()[6].orderInformation().length')
    assert_equal 'qbGJGxVjhsCx/JR42Bd7tX4nbBYNgR/TehN7gQ==', @context.eval('e2e_patient.medications()[6].orderInformation()[0]["json"]["performer"]["family_name"]')
    assert_equal '', @context.eval('e2e_patient.medications()[6].orderInformation()[0]["json"]["performer"]["given_name"]')
    assert_equal '', @context.eval('e2e_patient.medications()[6].orderInformation()[0]["json"]["performer"]["npi"]')
    assert_equal Time.gm(2013,9,27).to_i, @context.eval('e2e_patient.medications()[6].orderInformation()[0].orderDateTime()').to_i

    #8th
    assert_equal true, @context.eval('e2e_patient.medications()[7].includesCodeFrom({"HC-DIN": ["02364948"]})')
    assert_equal true, @context.eval('e2e_patient.medications()[7].includesCodeFrom({"whoATC": ["C07AG02"]})')
    assert_equal ' E2E_LONG_TERM_FLAG', @context.eval('e2e_patient.medications()[7].freeTextSig()')
    assert_equal 1, @context.eval('e2e_patient.medications()[7].values().length')
    assert_equal 12.5, @context.eval('e2e_patient.medications()[7].values()[0].scalar()')
    assert_equal 'MG', @context.eval('e2e_patient.medications()[7].values()[0].units()')
    assert_equal 'active', @context.eval('e2e_patient.medications()[7]["json"]["statusOfMedication"]["value"]')
    assert_equal 2013, @context.eval('e2e_patient.medications()[7].timeStamp().getUTCFullYear()')
    assert_equal 8, @context.eval('e2e_patient.medications()[7].timeStamp().getUTCMonth()')
    assert_equal 27, @context.eval('e2e_patient.medications()[7].timeStamp().getUTCDate()')
    assert_equal 1, @context.eval('e2e_patient.medications()[7].orderInformation().length')
    assert_equal 'qbGJGxVjhsCx/JR42Bd7tX4nbBYNgR/TehN7gQ==', @context.eval('e2e_patient.medications()[7].orderInformation()[0]["json"]["performer"]["family_name"]')
    assert_equal '', @context.eval('e2e_patient.medications()[7].orderInformation()[0]["json"]["performer"]["given_name"]')
    assert_equal '', @context.eval('e2e_patient.medications()[7].orderInformation()[0]["json"]["performer"]["npi"]')
    assert_equal Time.gm(2013,9,27).to_i, @context.eval('e2e_patient.medications()[7].orderInformation()[0].orderDateTime()').to_i

    #9th and last
    assert_equal true, @context.eval('e2e_patient.medications()[8].includesCodeFrom({"HC-DIN": ["02387913"]})')
    assert_equal true, @context.eval('e2e_patient.medications()[8].includesCodeFrom({"whoATC": ["C10AA05"]})')
    assert_equal ' E2E_LONG_TERM_FLAG', @context.eval('e2e_patient.medications()[8].freeTextSig()')
    assert_equal 1, @context.eval('e2e_patient.medications()[8].values().length')
    assert_equal 40, @context.eval('e2e_patient.medications()[8].values()[0].scalar()')
    assert_equal 'MG', @context.eval('e2e_patient.medications()[8].values()[0].units()')
    assert_equal 'active', @context.eval('e2e_patient.medications()[8]["json"]["statusOfMedication"]["value"]')
    assert_equal 2013, @context.eval('e2e_patient.medications()[8].timeStamp().getUTCFullYear()')
    assert_equal 8, @context.eval('e2e_patient.medications()[8].timeStamp().getUTCMonth()')
    assert_equal 27, @context.eval('e2e_patient.medications()[8].timeStamp().getUTCDate()')
    assert_equal 1, @context.eval('e2e_patient.medications()[8].orderInformation().length')
    assert_equal 'qbGJGxVjhsCx/JR42Bd7tX4nbBYNgR/TehN7gQ==', @context.eval('e2e_patient.medications()[8].orderInformation()[0]["json"]["performer"]["family_name"]')
    assert_equal '', @context.eval('e2e_patient.medications()[8].orderInformation()[0]["json"]["performer"]["given_name"]')
    assert_equal '', @context.eval('e2e_patient.medications()[8].orderInformation()[0]["json"]["performer"]["npi"]')
    assert_equal Time.gm(2013,9,27).to_i, @context.eval('e2e_patient.medications()[8].orderInformation()[0].orderDateTime()').to_i

  end
end



class E2EMedicationsImporterApiTest2 < E2EImporterApiTest2
  def test_e2e_medications_importing_zarilla
    assert_equal 7, @context.eval('e2e_patient2.medications().length')
    assert @context.eval('e2e_patient2.medications().match({"HC-DIN": ["2139324"]})')
    assert @context.eval('e2e_patient2.medications().match({"whoATC": ["N02BE01"]}).length == 0')

    # test importing of medication strengths, prescription date, instructions to patient
    #1st
    assert_equal true, @context.eval('e2e_patient2.medications()[0].includesCodeFrom({"HC-DIN": ["2241497"]})')
    assert_equal 1, @context.eval('e2e_patient2.medications()[0].values().length')
    assert_equal 100, @context.eval('e2e_patient2.medications()[0].values()[0].scalar()')
    assert_equal 'Mcg', @context.eval('e2e_patient2.medications()[0].values()[0].units()')
    assert_equal 'active', @context.eval('e2e_patient2.medications()[0]["json"]["statusOfMedication"]["value"]')
    assert_equal Time.gm(2013,11,6), @context.eval('e2e_patient2.medications()[0].timeStamp()')
    assert_equal 2013, @context.eval('e2e_patient2.medications()[0].timeStamp().getUTCFullYear()')
    assert_equal 10, @context.eval('e2e_patient2.medications()[0].timeStamp().getUTCMonth()')
    assert_equal 6, @context.eval('e2e_patient2.medications()[0].timeStamp().getUTCDate()')
    assert_equal 1, @context.eval('e2e_patient2.medications()[0].orderInformation().length')
    assert_equal '[Frequency: Four times daily]', @context.eval('e2e_patient2.medications()[0].administrationTiming()["json"]["text"]')
    assert_equal '1-2 Puffs four times daily for 30 days. Use with Aerochamber', @context.eval('e2e_patient2.medications()[0].freeTextSig()')
    #No useful provider information in this document,  Family name is hash of empty string.
    assert_equal '0UoCjCo6K8lHYQK7KII0xBWisB+CjqYqxbPkLw==', @context.eval('e2e_patient2.medications()[0].orderInformation()[0]["json"]["performer"]["family_name"]')
    assert_equal '', @context.eval('e2e_patient2.medications()[0].orderInformation()[0]["json"]["performer"]["given_name"]')
    assert_equal '', @context.eval('e2e_patient2.medications()[0].orderInformation()[0]["json"]["performer"]["npi"]')
    assert_equal nil, @context.eval('e2e_patient2.medications()[0].orderInformation()[0]["json"]["performer"]["start"]')

    #2nd
    assert_equal true, @context.eval('e2e_patient2.medications()[1].includesCodeFrom({"HC-DIN": ["682020"]})')
    assert_equal 1, @context.eval('e2e_patient2.medications()[1].values().length')
    assert_equal 1, @context.eval('e2e_patient2.medications()[1].values()[0].scalar()')
    assert_equal 'Tablet(s)', @context.eval('e2e_patient2.medications()[1].values()[0].units()')
    assert_equal 'active', @context.eval('e2e_patient2.medications()[1]["json"]["statusOfMedication"]["value"]')
    assert_equal 'Take with Food', @context.eval('e2e_patient2.medications()[1].freeTextSig()')
    assert_equal Time.gm(2014,2,13), @context.eval('e2e_patient2.medications()[1].timeStamp()')
    assert_equal 2014, @context.eval('e2e_patient2.medications()[1].timeStamp().getUTCFullYear()')
    assert_equal 1, @context.eval('e2e_patient2.medications()[1].timeStamp().getUTCMonth()')
    assert_equal 13, @context.eval('e2e_patient2.medications()[1].timeStamp().getUTCDate()')
    assert_equal '[Frequency: Four times daily]', @context.eval('e2e_patient2.medications()[1].administrationTiming()["json"]["text"]')

    #3rd
    assert_equal true, @context.eval('e2e_patient2.medications()[2].includesCodeFrom({"Unknown": ["NI"]})')
    assert_equal 1, @context.eval('e2e_patient2.medications()[2].values().length')
    assert_equal 5, @context.eval('e2e_patient2.medications()[2].values()[0].scalar()')
    assert_equal 'Mg', @context.eval('e2e_patient2.medications()[2].values()[0].units()')
    assert_equal 'active', @context.eval('e2e_patient2.medications()[2]["json"]["statusOfMedication"]["value"]')
    assert_equal 'One capsule daily at bedtime as needed
. Take at bedtime E2E_PRN_FLAG', @context.eval('e2e_patient2.medications()[2].freeTextSig()')
    assert_equal Time.gm(2014,2,4), @context.eval('e2e_patient2.medications()[2].timeStamp()')
    assert_equal 2014, @context.eval('e2e_patient2.medications()[2].timeStamp().getUTCFullYear()')
    assert_equal 1, @context.eval('e2e_patient2.medications()[2].timeStamp().getUTCMonth()')
    assert_equal 4, @context.eval('e2e_patient2.medications()[2].timeStamp().getUTCDate()')
    assert_equal '[Frequency: Once daily]', @context.eval('e2e_patient2.medications()[2].administrationTiming()["json"]["text"]')

    #4th
    assert_equal true, @context.eval('e2e_patient2.medications()[3].includesCodeFrom({"HC-DIN": ["2243224"]})')
    assert_equal 1, @context.eval('e2e_patient2.medications()[3].values().length')
    assert_equal 125, @context.eval('e2e_patient2.medications()[3].values()[0].scalar()')
    assert_equal 'Mg', @context.eval('e2e_patient2.medications()[3].values()[0].units()')
    assert_equal 'completed', @context.eval('e2e_patient2.medications()[3]["json"]["statusOfMedication"]["value"]')
    assert_equal '125mg (5ml) three times daily
. Shake well before use and take until finished', @context.eval('e2e_patient2.medications()[3].freeTextSig()')
    assert_equal Time.gm(2014,2,27), @context.eval('e2e_patient2.medications()[3].timeStamp()')
    assert_equal 2014, @context.eval('e2e_patient2.medications()[3].timeStamp().getUTCFullYear()')
    assert_equal 1, @context.eval('e2e_patient2.medications()[3].timeStamp().getUTCMonth()')
    assert_equal 27, @context.eval('e2e_patient2.medications()[3].timeStamp().getUTCDate()')
    assert_equal '[Frequency: Three times daily]', @context.eval('e2e_patient2.medications()[3].administrationTiming()["json"]["text"]')

    #5th
    assert_equal true, @context.eval('e2e_patient2.medications()[4].includesCodeFrom({"HC-DIN": ["2139324"]})')
    assert_equal 1, @context.eval('e2e_patient2.medications()[4].values().length')
    assert_equal 1, @context.eval('e2e_patient2.medications()[4].values()[0].scalar()')
    assert_equal 'Millilitres', @context.eval('e2e_patient2.medications()[4].values()[0].units()')
    assert_equal 'active', @context.eval('e2e_patient2.medications()[4]["json"]["statusOfMedication"]["value"]')
    assert_equal '1ml with 5ml Normal saline by Nebulizer twice daily.', @context.eval('e2e_patient2.medications()[4].freeTextSig()')
    assert_equal Time.gm(2014,1,5), @context.eval('e2e_patient2.medications()[4].timeStamp()')
    assert_equal 2014, @context.eval('e2e_patient2.medications()[4].timeStamp().getUTCFullYear()')
    assert_equal 0, @context.eval('e2e_patient2.medications()[4].timeStamp().getUTCMonth()')
    assert_equal 5, @context.eval('e2e_patient2.medications()[4].timeStamp().getUTCDate()')
    assert_equal '[Frequency: Twice daily]', @context.eval('e2e_patient2.medications()[4].administrationTiming()["json"]["text"]')

    #6th
    assert_equal true, @context.eval('e2e_patient2.medications()[5].includesCodeFrom({"HC-DIN": ["1999761"]})')
    assert_equal 1, @context.eval('e2e_patient2.medications()[5].values().length')
    assert_equal 5, @context.eval('e2e_patient2.medications()[5].values()[0].scalar()')
    assert_equal 'Mg', @context.eval('e2e_patient2.medications()[5].values()[0].units()')
    assert_equal 'active', @context.eval('e2e_patient2.medications()[5]["json"]["statusOfMedication"]["value"]')
    assert_equal '5mg administered intra-articularly to right foot monthly. Bring medication to Doctor\'s office for administration.', @context.eval('e2e_patient2.medications()[5].freeTextSig()')
    assert_equal Time.gm(2014,2,4), @context.eval('e2e_patient2.medications()[5].timeStamp()')
    assert_equal 2014, @context.eval('e2e_patient2.medications()[5].timeStamp().getUTCFullYear()')
    assert_equal 1, @context.eval('e2e_patient2.medications()[5].timeStamp().getUTCMonth()')
    assert_equal 4, @context.eval('e2e_patient2.medications()[5].timeStamp().getUTCDate()')
    assert_equal '[Frequency: Once a month]', @context.eval('e2e_patient2.medications()[5].administrationTiming()["json"]["text"]')

    #7th
    assert_equal true, @context.eval('e2e_patient2.medications()[6].includesCodeFrom({"HC-DIN": ["2273950"]})')
    assert_equal 1, @context.eval('e2e_patient2.medications()[6].values().length')
    assert_equal 5, @context.eval('e2e_patient2.medications()[6].values()[0].scalar()')
    assert_equal 'Mg', @context.eval('e2e_patient2.medications()[6].values()[0].units()')
    assert_equal 'completed', @context.eval('e2e_patient2.medications()[6]["json"]["statusOfMedication"]["value"]')
    assert_equal '5mg twice daily.', @context.eval('e2e_patient2.medications()[6].freeTextSig()')
    assert_equal Time.gm(2013,12,6), @context.eval('e2e_patient2.medications()[6].timeStamp()')
    assert_equal 2013, @context.eval('e2e_patient2.medications()[6].timeStamp().getUTCFullYear()')
    assert_equal 11, @context.eval('e2e_patient2.medications()[6].timeStamp().getUTCMonth()')
    assert_equal 6, @context.eval('e2e_patient2.medications()[6].timeStamp().getUTCDate()')
    assert_equal '[Frequency: Twice daily]', @context.eval('e2e_patient2.medications()[6].administrationTiming()["json"]["text"]')

  end
end