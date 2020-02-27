var fs = require('fs');

const scenarioMappingPath = process.argv[2] || './examples/scenariomap.json';
const diffPath = process.argv[3] || './examples/diff.json';
const keyField = process.argv[4] || "conversationId";

const scenarioMapObj = JSON.parse(fs.readFileSync(scenarioMappingPath, 'utf8')) || [];
const diffObj = JSON.parse(fs.readFileSync(diffPath, 'utf8'));

const missingKeysKey = `missing-${keyField}`;
const unexpectedKeysKey = `unexpected-${keyField}`;

const scenariosWithMissingKeys = [],
    scenariosWithUnexpectedKeys = [],
    scenariosWithAddedFields = [],
    scenariosWithDeletedFields = [],
    scenariosWithUpdatedFields = [],
    orphans = []; // a 'debug' array in which I put all the values not matched to a scenario (should not happen, or maybe only for unxpected which came out of the blue)

const getScenarioForKeyValue = 
    (keyValue) => scenarioMapObj.find(scenario => scenario[keyField] && scenario[keyField].includes(keyValue));

const addScenarioInArray = (scenario, keyValue, target) => {
    const scenarioInArray = target.find(_ => _.name === scenario.name);
    if (!!scenarioInArray){
    // already there? add a value in the [keyField] array
        scenarioInArray[keyField].push(keyValue); 
    } else {
    // not there? create/push obj
        target.push({
                name: scenario.name,
                [keyField]: [keyValue]
            }); 
    }
};

const unexpectedAndMissingScenarioFunc = (arrayToIterate, arrayToPopulate) => {
    arrayToIterate.forEach(keyValue => {
    const scenario = getScenarioForKeyValue(keyValue);

    if (!!scenario) {
        addScenarioInArray(scenario, keyValue, arrayToPopulate);
    } else {
        orphans.push(keyValue);
    }});
};

unexpectedAndMissingScenarioFunc(diffObj[missingKeysKey], scenariosWithMissingKeys);
unexpectedAndMissingScenarioFunc(diffObj[unexpectedKeysKey], scenariosWithUnexpectedKeys);

diffObj.diffs.forEach(diff => {
    const keyValue = diff[keyField];
    // https://www.npmjs.com/package/deep-object-diff

    const hasAdded = diff.diffs.findIndex(_ => 'added' in _) > -1;
    const hasDeleted = diff.diffs.findIndex(_ => 'deleted' in _) > -1;
    const hasUpdated = diff.diffs.findIndex(_ => 'updated' in _) > -1;

    const scenario = getScenarioForKeyValue(keyValue);
    if (!!scenario) {
        if (hasAdded)   addScenarioInArray(scenario, keyValue, scenariosWithAddedFields);
        if (hasDeleted) addScenarioInArray(scenario, keyValue, scenariosWithDeletedFields);
        if (hasUpdated) addScenarioInArray(scenario, keyValue, scenariosWithUpdatedFields);
    } else {
        orphans.push(keyValue);
    }
});

const result = {
    "scenariosWithMissingKeys": scenariosWithMissingKeys,
    "scenariosWithUnexpectedKeys": scenariosWithUnexpectedKeys,
    "scenariosWithAddedFields": scenariosWithAddedFields,
    "scenariosWithDeletedFields": scenariosWithDeletedFields,
    "scenariosWithUpdatedFields": scenariosWithUpdatedFields,
    "orphans": orphans
};

// send result to stdout
console.log(JSON.stringify(result,
    (_, v) => v === undefined ? null : v,
    2));