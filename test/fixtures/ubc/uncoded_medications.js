// Reference Number: UBC-007
// Query Title: Prescriptions without medication codes
//
// Equivalent SQL:
//
// Numerator:
// SELECT
//  COUNT(d.drugid) AS Count
// FROM
//  drugs AS d
// WHERE
//  d.rx_date >= DATE_SUB( NOW(), INTERVAL 12 MONTH ) AND
//  (d.regional_identifier IS NULL OR d.regional_identifier = '') AND
//  (d.ATC IS NULL OR d.ATC = '')
//
// Denominator:
// SELECT
//  COUNT(d.drugid) AS Count
// FROM
//  drugs AS d
// WHERE
//  d.rx_date >= DATE_SUB( NOW(), INTERVAL 12 MONTH )

function map(patient) {
    var now = new Date();
    var startDate = addDate(now, -1, 0, 0); // last 12 months

    var drugList = patient.medications();
    var currentDrugs;

    if (drugList === null || drugList.length === 0) {
        emit('medication_no_record', 1);
    } else {
        currentDrugs = findCurrentDrugs(drugList);
    }

    // Shifts date by year, month, and date specified
    function addDate(date, y, m, d) {
        var n = new Date(date);
        n.setFullYear(date.getFullYear() + (y || 0));
        n.setMonth(date.getMonth() + (m || 0));
        n.setDate(date.getDate() + (d || 0));
        return n;
    }

    function isCurrentDrug(drug) {
        var start = drug.indicateMedicationStart().getTime();
        return (start >= startDate);
    }

    // Find uncoded drugs that are between start & end date
    function findCurrentDrugs(drugs) {

        for(var i = 0; i < drugs.length; i++) {

            var codes = drugs[i].medicationInformation().codedProduct();

            if (codes === null || codes.length === 0) {
                emit('medication_no_codedProduct', 1);
            } else {
                // Check if drug is within the right time
                var j;
                if(isCurrentDrug(drugs[i])) {
                    for (j = 0; j < codes.length; j++) {
                        // check for missing DIN or ATC codes
                        if (codes[j].codeSystemName().toLowerCase() !== null &&
                            codes[j].codeSystemName().toLowerCase() !== "whoATC".toLowerCase() &&
                            codes[j].codeSystemName().toLowerCase() !== "HC-DIN".toLowerCase()) {
                            emit('medication_last12months_uncoded', 1);
                        } else {
                          emit('medication_last12months_coded_'+codes[j].codeSystemName().toLowerCase(), 1);
                        }
                    }
                } else {
                    for (j = 0; j < codes.length; j++) {
                        if (codes[j].codeSystemName().toLowerCase() !== null &&
                            codes[j].codeSystemName().toLowerCase() !== "whoATC".toLowerCase() &&
                            codes[j].codeSystemName().toLowerCase() !== "HC-DIN".toLowerCase()) {
                            emit('medication_prior_to_last12months_uncoded', 1);
                        } else {
                            emit('medication_prior_to_last12months_coded_'+codes[j].codeSystemName().toLowerCase(), 1);
                        }
                    }
                }
            }
        }
    }

    emit('total_population', 1);

    // Empty Case
    emit('medication_no_record', 0);
    emit('medication_no_codedProduct', 0);
    emit('medication_last12months_uncoded', 0);
    emit('medication_prior_to_last12months_uncoded', 0);
}