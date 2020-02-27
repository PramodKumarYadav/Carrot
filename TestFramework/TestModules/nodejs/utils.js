var deepDiff = require('deep-object-diff');

function isEmpty(obj) {
    for(var key in obj) {
        if(obj.hasOwnProperty(key))
            return false;
    }
    return true;
}

exports.objDiff = (obj1, obj2) => deepDiff.detailedDiff(obj1, obj2);
exports.isEmpty = isEmpty;