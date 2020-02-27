const fs = require('fs');
const utils = require('./utils');

const expectedPath = process.argv[2] || './examples/expected.json';
const actualPath = process.argv[3] || './examples/actual.json';
const keyField = process.argv[4] || "conversationId";

// if expected is an empty file, treat it as an empty array
const expectedObj = JSON.parse(fs.readFileSync(expectedPath, 'utf8') || '[]');
const actualObj = JSON.parse(fs.readFileSync(actualPath, 'utf8') || '[]');

// maps with key = id, value = obj
const mapExpected = new Map(expectedObj.map(msg => [msg[keyField], msg]));
const mapActual = new Map(actualObj.map(msg => [msg[keyField], msg]));

const expectedKeys = [...mapExpected.keys()];
const actualKeys = [...mapActual.keys()];

const missingInActual = expectedKeys.filter(x => !actualKeys.includes(x));
const unexpectedInActual = actualKeys.filter(x => !expectedKeys.includes(x));
const commonKeys = expectedKeys.filter(x => actualKeys.includes(x));
const diffs = [];

commonKeys.forEach(keyValue => {
    const expected = mapExpected.get(keyValue);
    const actual = mapActual.get(keyValue);

    const diff = utils.objDiff(expected, actual);
    const objDiffs = [];

    if (!utils.isEmpty(diff.added))
        objDiffs.push({ added: diff.added });

    if (!utils.isEmpty(diff.deleted))
        objDiffs.push({ deleted: diff.deleted });

    if (!utils.isEmpty(diff.updated))
        objDiffs.push({ updated: diff.updated });

    if (objDiffs.length > 0)
        diffs.push({
            [keyField]: keyValue,
            diffs: objDiffs
        });
});

const missingKeysKey = `missing-${keyField}`;
const unexpectedKeysKey = `unexpected-${keyField}`;

const result = {
    [missingKeysKey]: missingInActual,
    [unexpectedKeysKey]: unexpectedInActual,
    diffs: diffs
};

// send result to stdout
console.log(JSON.stringify(result,
    (_, v) => v === undefined ? null : v,
    2));