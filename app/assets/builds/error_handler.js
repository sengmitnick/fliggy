var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __commonJS = (cb, mod) => function __require() {
  return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));

// node_modules/source-map-js/lib/base64.js
var require_base64 = __commonJS({
  "node_modules/source-map-js/lib/base64.js"(exports) {
    var intToCharMap = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".split("");
    exports.encode = function(number) {
      if (0 <= number && number < intToCharMap.length) {
        return intToCharMap[number];
      }
      throw new TypeError("Must be between 0 and 63: " + number);
    };
    exports.decode = function(charCode) {
      var bigA = 65;
      var bigZ = 90;
      var littleA = 97;
      var littleZ = 122;
      var zero = 48;
      var nine = 57;
      var plus = 43;
      var slash = 47;
      var littleOffset = 26;
      var numberOffset = 52;
      if (bigA <= charCode && charCode <= bigZ) {
        return charCode - bigA;
      }
      if (littleA <= charCode && charCode <= littleZ) {
        return charCode - littleA + littleOffset;
      }
      if (zero <= charCode && charCode <= nine) {
        return charCode - zero + numberOffset;
      }
      if (charCode == plus) {
        return 62;
      }
      if (charCode == slash) {
        return 63;
      }
      return -1;
    };
  }
});

// node_modules/source-map-js/lib/base64-vlq.js
var require_base64_vlq = __commonJS({
  "node_modules/source-map-js/lib/base64-vlq.js"(exports) {
    var base64 = require_base64();
    var VLQ_BASE_SHIFT = 5;
    var VLQ_BASE = 1 << VLQ_BASE_SHIFT;
    var VLQ_BASE_MASK = VLQ_BASE - 1;
    var VLQ_CONTINUATION_BIT = VLQ_BASE;
    function toVLQSigned(aValue) {
      return aValue < 0 ? (-aValue << 1) + 1 : (aValue << 1) + 0;
    }
    function fromVLQSigned(aValue) {
      var isNegative = (aValue & 1) === 1;
      var shifted = aValue >> 1;
      return isNegative ? -shifted : shifted;
    }
    exports.encode = function base64VLQ_encode(aValue) {
      var encoded = "";
      var digit;
      var vlq = toVLQSigned(aValue);
      do {
        digit = vlq & VLQ_BASE_MASK;
        vlq >>>= VLQ_BASE_SHIFT;
        if (vlq > 0) {
          digit |= VLQ_CONTINUATION_BIT;
        }
        encoded += base64.encode(digit);
      } while (vlq > 0);
      return encoded;
    };
    exports.decode = function base64VLQ_decode(aStr, aIndex, aOutParam) {
      var strLen = aStr.length;
      var result = 0;
      var shift = 0;
      var continuation, digit;
      do {
        if (aIndex >= strLen) {
          throw new Error("Expected more digits in base 64 VLQ value.");
        }
        digit = base64.decode(aStr.charCodeAt(aIndex++));
        if (digit === -1) {
          throw new Error("Invalid base64 digit: " + aStr.charAt(aIndex - 1));
        }
        continuation = !!(digit & VLQ_CONTINUATION_BIT);
        digit &= VLQ_BASE_MASK;
        result = result + (digit << shift);
        shift += VLQ_BASE_SHIFT;
      } while (continuation);
      aOutParam.value = fromVLQSigned(result);
      aOutParam.rest = aIndex;
    };
  }
});

// node_modules/source-map-js/lib/util.js
var require_util = __commonJS({
  "node_modules/source-map-js/lib/util.js"(exports) {
    function getArg(aArgs, aName, aDefaultValue) {
      if (aName in aArgs) {
        return aArgs[aName];
      } else if (arguments.length === 3) {
        return aDefaultValue;
      } else {
        throw new Error('"' + aName + '" is a required argument.');
      }
    }
    exports.getArg = getArg;
    var urlRegexp = /^(?:([\w+\-.]+):)?\/\/(?:(\w+:\w+)@)?([\w.-]*)(?::(\d+))?(.*)$/;
    var dataUrlRegexp = /^data:.+\,.+$/;
    function urlParse(aUrl) {
      var match = aUrl.match(urlRegexp);
      if (!match) {
        return null;
      }
      return {
        scheme: match[1],
        auth: match[2],
        host: match[3],
        port: match[4],
        path: match[5]
      };
    }
    exports.urlParse = urlParse;
    function urlGenerate(aParsedUrl) {
      var url = "";
      if (aParsedUrl.scheme) {
        url += aParsedUrl.scheme + ":";
      }
      url += "//";
      if (aParsedUrl.auth) {
        url += aParsedUrl.auth + "@";
      }
      if (aParsedUrl.host) {
        url += aParsedUrl.host;
      }
      if (aParsedUrl.port) {
        url += ":" + aParsedUrl.port;
      }
      if (aParsedUrl.path) {
        url += aParsedUrl.path;
      }
      return url;
    }
    exports.urlGenerate = urlGenerate;
    var MAX_CACHED_INPUTS = 32;
    function lruMemoize(f) {
      var cache = [];
      return function(input) {
        for (var i = 0; i < cache.length; i++) {
          if (cache[i].input === input) {
            var temp = cache[0];
            cache[0] = cache[i];
            cache[i] = temp;
            return cache[0].result;
          }
        }
        var result = f(input);
        cache.unshift({
          input,
          result
        });
        if (cache.length > MAX_CACHED_INPUTS) {
          cache.pop();
        }
        return result;
      };
    }
    var normalize = lruMemoize(function normalize2(aPath) {
      var path = aPath;
      var url = urlParse(aPath);
      if (url) {
        if (!url.path) {
          return aPath;
        }
        path = url.path;
      }
      var isAbsolute = exports.isAbsolute(path);
      var parts = [];
      var start = 0;
      var i = 0;
      while (true) {
        start = i;
        i = path.indexOf("/", start);
        if (i === -1) {
          parts.push(path.slice(start));
          break;
        } else {
          parts.push(path.slice(start, i));
          while (i < path.length && path[i] === "/") {
            i++;
          }
        }
      }
      for (var part, up = 0, i = parts.length - 1; i >= 0; i--) {
        part = parts[i];
        if (part === ".") {
          parts.splice(i, 1);
        } else if (part === "..") {
          up++;
        } else if (up > 0) {
          if (part === "") {
            parts.splice(i + 1, up);
            up = 0;
          } else {
            parts.splice(i, 2);
            up--;
          }
        }
      }
      path = parts.join("/");
      if (path === "") {
        path = isAbsolute ? "/" : ".";
      }
      if (url) {
        url.path = path;
        return urlGenerate(url);
      }
      return path;
    });
    exports.normalize = normalize;
    function join(aRoot, aPath) {
      if (aRoot === "") {
        aRoot = ".";
      }
      if (aPath === "") {
        aPath = ".";
      }
      var aPathUrl = urlParse(aPath);
      var aRootUrl = urlParse(aRoot);
      if (aRootUrl) {
        aRoot = aRootUrl.path || "/";
      }
      if (aPathUrl && !aPathUrl.scheme) {
        if (aRootUrl) {
          aPathUrl.scheme = aRootUrl.scheme;
        }
        return urlGenerate(aPathUrl);
      }
      if (aPathUrl || aPath.match(dataUrlRegexp)) {
        return aPath;
      }
      if (aRootUrl && !aRootUrl.host && !aRootUrl.path) {
        aRootUrl.host = aPath;
        return urlGenerate(aRootUrl);
      }
      var joined = aPath.charAt(0) === "/" ? aPath : normalize(aRoot.replace(/\/+$/, "") + "/" + aPath);
      if (aRootUrl) {
        aRootUrl.path = joined;
        return urlGenerate(aRootUrl);
      }
      return joined;
    }
    exports.join = join;
    exports.isAbsolute = function(aPath) {
      return aPath.charAt(0) === "/" || urlRegexp.test(aPath);
    };
    function relative(aRoot, aPath) {
      if (aRoot === "") {
        aRoot = ".";
      }
      aRoot = aRoot.replace(/\/$/, "");
      var level = 0;
      while (aPath.indexOf(aRoot + "/") !== 0) {
        var index = aRoot.lastIndexOf("/");
        if (index < 0) {
          return aPath;
        }
        aRoot = aRoot.slice(0, index);
        if (aRoot.match(/^([^\/]+:\/)?\/*$/)) {
          return aPath;
        }
        ++level;
      }
      return Array(level + 1).join("../") + aPath.substr(aRoot.length + 1);
    }
    exports.relative = relative;
    var supportsNullProto = function() {
      var obj = /* @__PURE__ */ Object.create(null);
      return !("__proto__" in obj);
    }();
    function identity(s) {
      return s;
    }
    function toSetString(aStr) {
      if (isProtoString(aStr)) {
        return "$" + aStr;
      }
      return aStr;
    }
    exports.toSetString = supportsNullProto ? identity : toSetString;
    function fromSetString(aStr) {
      if (isProtoString(aStr)) {
        return aStr.slice(1);
      }
      return aStr;
    }
    exports.fromSetString = supportsNullProto ? identity : fromSetString;
    function isProtoString(s) {
      if (!s) {
        return false;
      }
      var length = s.length;
      if (length < 9) {
        return false;
      }
      if (s.charCodeAt(length - 1) !== 95 || s.charCodeAt(length - 2) !== 95 || s.charCodeAt(length - 3) !== 111 || s.charCodeAt(length - 4) !== 116 || s.charCodeAt(length - 5) !== 111 || s.charCodeAt(length - 6) !== 114 || s.charCodeAt(length - 7) !== 112 || s.charCodeAt(length - 8) !== 95 || s.charCodeAt(length - 9) !== 95) {
        return false;
      }
      for (var i = length - 10; i >= 0; i--) {
        if (s.charCodeAt(i) !== 36) {
          return false;
        }
      }
      return true;
    }
    function compareByOriginalPositions(mappingA, mappingB, onlyCompareOriginal) {
      var cmp = strcmp(mappingA.source, mappingB.source);
      if (cmp !== 0) {
        return cmp;
      }
      cmp = mappingA.originalLine - mappingB.originalLine;
      if (cmp !== 0) {
        return cmp;
      }
      cmp = mappingA.originalColumn - mappingB.originalColumn;
      if (cmp !== 0 || onlyCompareOriginal) {
        return cmp;
      }
      cmp = mappingA.generatedColumn - mappingB.generatedColumn;
      if (cmp !== 0) {
        return cmp;
      }
      cmp = mappingA.generatedLine - mappingB.generatedLine;
      if (cmp !== 0) {
        return cmp;
      }
      return strcmp(mappingA.name, mappingB.name);
    }
    exports.compareByOriginalPositions = compareByOriginalPositions;
    function compareByOriginalPositionsNoSource(mappingA, mappingB, onlyCompareOriginal) {
      var cmp;
      cmp = mappingA.originalLine - mappingB.originalLine;
      if (cmp !== 0) {
        return cmp;
      }
      cmp = mappingA.originalColumn - mappingB.originalColumn;
      if (cmp !== 0 || onlyCompareOriginal) {
        return cmp;
      }
      cmp = mappingA.generatedColumn - mappingB.generatedColumn;
      if (cmp !== 0) {
        return cmp;
      }
      cmp = mappingA.generatedLine - mappingB.generatedLine;
      if (cmp !== 0) {
        return cmp;
      }
      return strcmp(mappingA.name, mappingB.name);
    }
    exports.compareByOriginalPositionsNoSource = compareByOriginalPositionsNoSource;
    function compareByGeneratedPositionsDeflated(mappingA, mappingB, onlyCompareGenerated) {
      var cmp = mappingA.generatedLine - mappingB.generatedLine;
      if (cmp !== 0) {
        return cmp;
      }
      cmp = mappingA.generatedColumn - mappingB.generatedColumn;
      if (cmp !== 0 || onlyCompareGenerated) {
        return cmp;
      }
      cmp = strcmp(mappingA.source, mappingB.source);
      if (cmp !== 0) {
        return cmp;
      }
      cmp = mappingA.originalLine - mappingB.originalLine;
      if (cmp !== 0) {
        return cmp;
      }
      cmp = mappingA.originalColumn - mappingB.originalColumn;
      if (cmp !== 0) {
        return cmp;
      }
      return strcmp(mappingA.name, mappingB.name);
    }
    exports.compareByGeneratedPositionsDeflated = compareByGeneratedPositionsDeflated;
    function compareByGeneratedPositionsDeflatedNoLine(mappingA, mappingB, onlyCompareGenerated) {
      var cmp = mappingA.generatedColumn - mappingB.generatedColumn;
      if (cmp !== 0 || onlyCompareGenerated) {
        return cmp;
      }
      cmp = strcmp(mappingA.source, mappingB.source);
      if (cmp !== 0) {
        return cmp;
      }
      cmp = mappingA.originalLine - mappingB.originalLine;
      if (cmp !== 0) {
        return cmp;
      }
      cmp = mappingA.originalColumn - mappingB.originalColumn;
      if (cmp !== 0) {
        return cmp;
      }
      return strcmp(mappingA.name, mappingB.name);
    }
    exports.compareByGeneratedPositionsDeflatedNoLine = compareByGeneratedPositionsDeflatedNoLine;
    function strcmp(aStr1, aStr2) {
      if (aStr1 === aStr2) {
        return 0;
      }
      if (aStr1 === null) {
        return 1;
      }
      if (aStr2 === null) {
        return -1;
      }
      if (aStr1 > aStr2) {
        return 1;
      }
      return -1;
    }
    function compareByGeneratedPositionsInflated(mappingA, mappingB) {
      var cmp = mappingA.generatedLine - mappingB.generatedLine;
      if (cmp !== 0) {
        return cmp;
      }
      cmp = mappingA.generatedColumn - mappingB.generatedColumn;
      if (cmp !== 0) {
        return cmp;
      }
      cmp = strcmp(mappingA.source, mappingB.source);
      if (cmp !== 0) {
        return cmp;
      }
      cmp = mappingA.originalLine - mappingB.originalLine;
      if (cmp !== 0) {
        return cmp;
      }
      cmp = mappingA.originalColumn - mappingB.originalColumn;
      if (cmp !== 0) {
        return cmp;
      }
      return strcmp(mappingA.name, mappingB.name);
    }
    exports.compareByGeneratedPositionsInflated = compareByGeneratedPositionsInflated;
    function parseSourceMapInput(str) {
      return JSON.parse(str.replace(/^\)]}'[^\n]*\n/, ""));
    }
    exports.parseSourceMapInput = parseSourceMapInput;
    function computeSourceURL(sourceRoot, sourceURL, sourceMapURL) {
      sourceURL = sourceURL || "";
      if (sourceRoot) {
        if (sourceRoot[sourceRoot.length - 1] !== "/" && sourceURL[0] !== "/") {
          sourceRoot += "/";
        }
        sourceURL = sourceRoot + sourceURL;
      }
      if (sourceMapURL) {
        var parsed = urlParse(sourceMapURL);
        if (!parsed) {
          throw new Error("sourceMapURL could not be parsed");
        }
        if (parsed.path) {
          var index = parsed.path.lastIndexOf("/");
          if (index >= 0) {
            parsed.path = parsed.path.substring(0, index + 1);
          }
        }
        sourceURL = join(urlGenerate(parsed), sourceURL);
      }
      return normalize(sourceURL);
    }
    exports.computeSourceURL = computeSourceURL;
  }
});

// node_modules/source-map-js/lib/array-set.js
var require_array_set = __commonJS({
  "node_modules/source-map-js/lib/array-set.js"(exports) {
    var util = require_util();
    var has = Object.prototype.hasOwnProperty;
    var hasNativeMap = typeof Map !== "undefined";
    function ArraySet() {
      this._array = [];
      this._set = hasNativeMap ? /* @__PURE__ */ new Map() : /* @__PURE__ */ Object.create(null);
    }
    ArraySet.fromArray = function ArraySet_fromArray(aArray, aAllowDuplicates) {
      var set = new ArraySet();
      for (var i = 0, len = aArray.length; i < len; i++) {
        set.add(aArray[i], aAllowDuplicates);
      }
      return set;
    };
    ArraySet.prototype.size = function ArraySet_size() {
      return hasNativeMap ? this._set.size : Object.getOwnPropertyNames(this._set).length;
    };
    ArraySet.prototype.add = function ArraySet_add(aStr, aAllowDuplicates) {
      var sStr = hasNativeMap ? aStr : util.toSetString(aStr);
      var isDuplicate = hasNativeMap ? this.has(aStr) : has.call(this._set, sStr);
      var idx = this._array.length;
      if (!isDuplicate || aAllowDuplicates) {
        this._array.push(aStr);
      }
      if (!isDuplicate) {
        if (hasNativeMap) {
          this._set.set(aStr, idx);
        } else {
          this._set[sStr] = idx;
        }
      }
    };
    ArraySet.prototype.has = function ArraySet_has(aStr) {
      if (hasNativeMap) {
        return this._set.has(aStr);
      } else {
        var sStr = util.toSetString(aStr);
        return has.call(this._set, sStr);
      }
    };
    ArraySet.prototype.indexOf = function ArraySet_indexOf(aStr) {
      if (hasNativeMap) {
        var idx = this._set.get(aStr);
        if (idx >= 0) {
          return idx;
        }
      } else {
        var sStr = util.toSetString(aStr);
        if (has.call(this._set, sStr)) {
          return this._set[sStr];
        }
      }
      throw new Error('"' + aStr + '" is not in the set.');
    };
    ArraySet.prototype.at = function ArraySet_at(aIdx) {
      if (aIdx >= 0 && aIdx < this._array.length) {
        return this._array[aIdx];
      }
      throw new Error("No element indexed by " + aIdx);
    };
    ArraySet.prototype.toArray = function ArraySet_toArray() {
      return this._array.slice();
    };
    exports.ArraySet = ArraySet;
  }
});

// node_modules/source-map-js/lib/mapping-list.js
var require_mapping_list = __commonJS({
  "node_modules/source-map-js/lib/mapping-list.js"(exports) {
    var util = require_util();
    function generatedPositionAfter(mappingA, mappingB) {
      var lineA = mappingA.generatedLine;
      var lineB = mappingB.generatedLine;
      var columnA = mappingA.generatedColumn;
      var columnB = mappingB.generatedColumn;
      return lineB > lineA || lineB == lineA && columnB >= columnA || util.compareByGeneratedPositionsInflated(mappingA, mappingB) <= 0;
    }
    function MappingList() {
      this._array = [];
      this._sorted = true;
      this._last = { generatedLine: -1, generatedColumn: 0 };
    }
    MappingList.prototype.unsortedForEach = function MappingList_forEach(aCallback, aThisArg) {
      this._array.forEach(aCallback, aThisArg);
    };
    MappingList.prototype.add = function MappingList_add(aMapping) {
      if (generatedPositionAfter(this._last, aMapping)) {
        this._last = aMapping;
        this._array.push(aMapping);
      } else {
        this._sorted = false;
        this._array.push(aMapping);
      }
    };
    MappingList.prototype.toArray = function MappingList_toArray() {
      if (!this._sorted) {
        this._array.sort(util.compareByGeneratedPositionsInflated);
        this._sorted = true;
      }
      return this._array;
    };
    exports.MappingList = MappingList;
  }
});

// node_modules/source-map-js/lib/source-map-generator.js
var require_source_map_generator = __commonJS({
  "node_modules/source-map-js/lib/source-map-generator.js"(exports) {
    var base64VLQ = require_base64_vlq();
    var util = require_util();
    var ArraySet = require_array_set().ArraySet;
    var MappingList = require_mapping_list().MappingList;
    function SourceMapGenerator(aArgs) {
      if (!aArgs) {
        aArgs = {};
      }
      this._file = util.getArg(aArgs, "file", null);
      this._sourceRoot = util.getArg(aArgs, "sourceRoot", null);
      this._skipValidation = util.getArg(aArgs, "skipValidation", false);
      this._ignoreInvalidMapping = util.getArg(aArgs, "ignoreInvalidMapping", false);
      this._sources = new ArraySet();
      this._names = new ArraySet();
      this._mappings = new MappingList();
      this._sourcesContents = null;
    }
    SourceMapGenerator.prototype._version = 3;
    SourceMapGenerator.fromSourceMap = function SourceMapGenerator_fromSourceMap(aSourceMapConsumer, generatorOps) {
      var sourceRoot = aSourceMapConsumer.sourceRoot;
      var generator = new SourceMapGenerator(Object.assign(generatorOps || {}, {
        file: aSourceMapConsumer.file,
        sourceRoot
      }));
      aSourceMapConsumer.eachMapping(function(mapping) {
        var newMapping = {
          generated: {
            line: mapping.generatedLine,
            column: mapping.generatedColumn
          }
        };
        if (mapping.source != null) {
          newMapping.source = mapping.source;
          if (sourceRoot != null) {
            newMapping.source = util.relative(sourceRoot, newMapping.source);
          }
          newMapping.original = {
            line: mapping.originalLine,
            column: mapping.originalColumn
          };
          if (mapping.name != null) {
            newMapping.name = mapping.name;
          }
        }
        generator.addMapping(newMapping);
      });
      aSourceMapConsumer.sources.forEach(function(sourceFile) {
        var sourceRelative = sourceFile;
        if (sourceRoot !== null) {
          sourceRelative = util.relative(sourceRoot, sourceFile);
        }
        if (!generator._sources.has(sourceRelative)) {
          generator._sources.add(sourceRelative);
        }
        var content = aSourceMapConsumer.sourceContentFor(sourceFile);
        if (content != null) {
          generator.setSourceContent(sourceFile, content);
        }
      });
      return generator;
    };
    SourceMapGenerator.prototype.addMapping = function SourceMapGenerator_addMapping(aArgs) {
      var generated = util.getArg(aArgs, "generated");
      var original = util.getArg(aArgs, "original", null);
      var source = util.getArg(aArgs, "source", null);
      var name = util.getArg(aArgs, "name", null);
      if (!this._skipValidation) {
        if (this._validateMapping(generated, original, source, name) === false) {
          return;
        }
      }
      if (source != null) {
        source = String(source);
        if (!this._sources.has(source)) {
          this._sources.add(source);
        }
      }
      if (name != null) {
        name = String(name);
        if (!this._names.has(name)) {
          this._names.add(name);
        }
      }
      this._mappings.add({
        generatedLine: generated.line,
        generatedColumn: generated.column,
        originalLine: original != null && original.line,
        originalColumn: original != null && original.column,
        source,
        name
      });
    };
    SourceMapGenerator.prototype.setSourceContent = function SourceMapGenerator_setSourceContent(aSourceFile, aSourceContent) {
      var source = aSourceFile;
      if (this._sourceRoot != null) {
        source = util.relative(this._sourceRoot, source);
      }
      if (aSourceContent != null) {
        if (!this._sourcesContents) {
          this._sourcesContents = /* @__PURE__ */ Object.create(null);
        }
        this._sourcesContents[util.toSetString(source)] = aSourceContent;
      } else if (this._sourcesContents) {
        delete this._sourcesContents[util.toSetString(source)];
        if (Object.keys(this._sourcesContents).length === 0) {
          this._sourcesContents = null;
        }
      }
    };
    SourceMapGenerator.prototype.applySourceMap = function SourceMapGenerator_applySourceMap(aSourceMapConsumer, aSourceFile, aSourceMapPath) {
      var sourceFile = aSourceFile;
      if (aSourceFile == null) {
        if (aSourceMapConsumer.file == null) {
          throw new Error(
            `SourceMapGenerator.prototype.applySourceMap requires either an explicit source file, or the source map's "file" property. Both were omitted.`
          );
        }
        sourceFile = aSourceMapConsumer.file;
      }
      var sourceRoot = this._sourceRoot;
      if (sourceRoot != null) {
        sourceFile = util.relative(sourceRoot, sourceFile);
      }
      var newSources = new ArraySet();
      var newNames = new ArraySet();
      this._mappings.unsortedForEach(function(mapping) {
        if (mapping.source === sourceFile && mapping.originalLine != null) {
          var original = aSourceMapConsumer.originalPositionFor({
            line: mapping.originalLine,
            column: mapping.originalColumn
          });
          if (original.source != null) {
            mapping.source = original.source;
            if (aSourceMapPath != null) {
              mapping.source = util.join(aSourceMapPath, mapping.source);
            }
            if (sourceRoot != null) {
              mapping.source = util.relative(sourceRoot, mapping.source);
            }
            mapping.originalLine = original.line;
            mapping.originalColumn = original.column;
            if (original.name != null) {
              mapping.name = original.name;
            }
          }
        }
        var source = mapping.source;
        if (source != null && !newSources.has(source)) {
          newSources.add(source);
        }
        var name = mapping.name;
        if (name != null && !newNames.has(name)) {
          newNames.add(name);
        }
      }, this);
      this._sources = newSources;
      this._names = newNames;
      aSourceMapConsumer.sources.forEach(function(sourceFile2) {
        var content = aSourceMapConsumer.sourceContentFor(sourceFile2);
        if (content != null) {
          if (aSourceMapPath != null) {
            sourceFile2 = util.join(aSourceMapPath, sourceFile2);
          }
          if (sourceRoot != null) {
            sourceFile2 = util.relative(sourceRoot, sourceFile2);
          }
          this.setSourceContent(sourceFile2, content);
        }
      }, this);
    };
    SourceMapGenerator.prototype._validateMapping = function SourceMapGenerator_validateMapping(aGenerated, aOriginal, aSource, aName) {
      if (aOriginal && typeof aOriginal.line !== "number" && typeof aOriginal.column !== "number") {
        var message = "original.line and original.column are not numbers -- you probably meant to omit the original mapping entirely and only map the generated position. If so, pass null for the original mapping instead of an object with empty or null values.";
        if (this._ignoreInvalidMapping) {
          if (typeof console !== "undefined" && console.warn) {
            console.warn(message);
          }
          return false;
        } else {
          throw new Error(message);
        }
      }
      if (aGenerated && "line" in aGenerated && "column" in aGenerated && aGenerated.line > 0 && aGenerated.column >= 0 && !aOriginal && !aSource && !aName) {
        return;
      } else if (aGenerated && "line" in aGenerated && "column" in aGenerated && aOriginal && "line" in aOriginal && "column" in aOriginal && aGenerated.line > 0 && aGenerated.column >= 0 && aOriginal.line > 0 && aOriginal.column >= 0 && aSource) {
        return;
      } else {
        var message = "Invalid mapping: " + JSON.stringify({
          generated: aGenerated,
          source: aSource,
          original: aOriginal,
          name: aName
        });
        if (this._ignoreInvalidMapping) {
          if (typeof console !== "undefined" && console.warn) {
            console.warn(message);
          }
          return false;
        } else {
          throw new Error(message);
        }
      }
    };
    SourceMapGenerator.prototype._serializeMappings = function SourceMapGenerator_serializeMappings() {
      var previousGeneratedColumn = 0;
      var previousGeneratedLine = 1;
      var previousOriginalColumn = 0;
      var previousOriginalLine = 0;
      var previousName = 0;
      var previousSource = 0;
      var result = "";
      var next;
      var mapping;
      var nameIdx;
      var sourceIdx;
      var mappings = this._mappings.toArray();
      for (var i = 0, len = mappings.length; i < len; i++) {
        mapping = mappings[i];
        next = "";
        if (mapping.generatedLine !== previousGeneratedLine) {
          previousGeneratedColumn = 0;
          while (mapping.generatedLine !== previousGeneratedLine) {
            next += ";";
            previousGeneratedLine++;
          }
        } else {
          if (i > 0) {
            if (!util.compareByGeneratedPositionsInflated(mapping, mappings[i - 1])) {
              continue;
            }
            next += ",";
          }
        }
        next += base64VLQ.encode(mapping.generatedColumn - previousGeneratedColumn);
        previousGeneratedColumn = mapping.generatedColumn;
        if (mapping.source != null) {
          sourceIdx = this._sources.indexOf(mapping.source);
          next += base64VLQ.encode(sourceIdx - previousSource);
          previousSource = sourceIdx;
          next += base64VLQ.encode(mapping.originalLine - 1 - previousOriginalLine);
          previousOriginalLine = mapping.originalLine - 1;
          next += base64VLQ.encode(mapping.originalColumn - previousOriginalColumn);
          previousOriginalColumn = mapping.originalColumn;
          if (mapping.name != null) {
            nameIdx = this._names.indexOf(mapping.name);
            next += base64VLQ.encode(nameIdx - previousName);
            previousName = nameIdx;
          }
        }
        result += next;
      }
      return result;
    };
    SourceMapGenerator.prototype._generateSourcesContent = function SourceMapGenerator_generateSourcesContent(aSources, aSourceRoot) {
      return aSources.map(function(source) {
        if (!this._sourcesContents) {
          return null;
        }
        if (aSourceRoot != null) {
          source = util.relative(aSourceRoot, source);
        }
        var key = util.toSetString(source);
        return Object.prototype.hasOwnProperty.call(this._sourcesContents, key) ? this._sourcesContents[key] : null;
      }, this);
    };
    SourceMapGenerator.prototype.toJSON = function SourceMapGenerator_toJSON() {
      var map = {
        version: this._version,
        sources: this._sources.toArray(),
        names: this._names.toArray(),
        mappings: this._serializeMappings()
      };
      if (this._file != null) {
        map.file = this._file;
      }
      if (this._sourceRoot != null) {
        map.sourceRoot = this._sourceRoot;
      }
      if (this._sourcesContents) {
        map.sourcesContent = this._generateSourcesContent(map.sources, map.sourceRoot);
      }
      return map;
    };
    SourceMapGenerator.prototype.toString = function SourceMapGenerator_toString() {
      return JSON.stringify(this.toJSON());
    };
    exports.SourceMapGenerator = SourceMapGenerator;
  }
});

// node_modules/source-map-js/lib/binary-search.js
var require_binary_search = __commonJS({
  "node_modules/source-map-js/lib/binary-search.js"(exports) {
    exports.GREATEST_LOWER_BOUND = 1;
    exports.LEAST_UPPER_BOUND = 2;
    function recursiveSearch(aLow, aHigh, aNeedle, aHaystack, aCompare, aBias) {
      var mid = Math.floor((aHigh - aLow) / 2) + aLow;
      var cmp = aCompare(aNeedle, aHaystack[mid], true);
      if (cmp === 0) {
        return mid;
      } else if (cmp > 0) {
        if (aHigh - mid > 1) {
          return recursiveSearch(mid, aHigh, aNeedle, aHaystack, aCompare, aBias);
        }
        if (aBias == exports.LEAST_UPPER_BOUND) {
          return aHigh < aHaystack.length ? aHigh : -1;
        } else {
          return mid;
        }
      } else {
        if (mid - aLow > 1) {
          return recursiveSearch(aLow, mid, aNeedle, aHaystack, aCompare, aBias);
        }
        if (aBias == exports.LEAST_UPPER_BOUND) {
          return mid;
        } else {
          return aLow < 0 ? -1 : aLow;
        }
      }
    }
    exports.search = function search(aNeedle, aHaystack, aCompare, aBias) {
      if (aHaystack.length === 0) {
        return -1;
      }
      var index = recursiveSearch(
        -1,
        aHaystack.length,
        aNeedle,
        aHaystack,
        aCompare,
        aBias || exports.GREATEST_LOWER_BOUND
      );
      if (index < 0) {
        return -1;
      }
      while (index - 1 >= 0) {
        if (aCompare(aHaystack[index], aHaystack[index - 1], true) !== 0) {
          break;
        }
        --index;
      }
      return index;
    };
  }
});

// node_modules/source-map-js/lib/quick-sort.js
var require_quick_sort = __commonJS({
  "node_modules/source-map-js/lib/quick-sort.js"(exports) {
    function SortTemplate(comparator) {
      function swap(ary, x, y) {
        var temp = ary[x];
        ary[x] = ary[y];
        ary[y] = temp;
      }
      function randomIntInRange(low, high) {
        return Math.round(low + Math.random() * (high - low));
      }
      function doQuickSort(ary, comparator2, p, r) {
        if (p < r) {
          var pivotIndex = randomIntInRange(p, r);
          var i = p - 1;
          swap(ary, pivotIndex, r);
          var pivot = ary[r];
          for (var j = p; j < r; j++) {
            if (comparator2(ary[j], pivot, false) <= 0) {
              i += 1;
              swap(ary, i, j);
            }
          }
          swap(ary, i + 1, j);
          var q = i + 1;
          doQuickSort(ary, comparator2, p, q - 1);
          doQuickSort(ary, comparator2, q + 1, r);
        }
      }
      return doQuickSort;
    }
    function cloneSort(comparator) {
      let template = SortTemplate.toString();
      let templateFn = new Function(`return ${template}`)();
      return templateFn(comparator);
    }
    var sortCache = /* @__PURE__ */ new WeakMap();
    exports.quickSort = function(ary, comparator, start = 0) {
      let doQuickSort = sortCache.get(comparator);
      if (doQuickSort === void 0) {
        doQuickSort = cloneSort(comparator);
        sortCache.set(comparator, doQuickSort);
      }
      doQuickSort(ary, comparator, start, ary.length - 1);
    };
  }
});

// node_modules/source-map-js/lib/source-map-consumer.js
var require_source_map_consumer = __commonJS({
  "node_modules/source-map-js/lib/source-map-consumer.js"(exports) {
    var util = require_util();
    var binarySearch = require_binary_search();
    var ArraySet = require_array_set().ArraySet;
    var base64VLQ = require_base64_vlq();
    var quickSort = require_quick_sort().quickSort;
    function SourceMapConsumer2(aSourceMap, aSourceMapURL) {
      var sourceMap = aSourceMap;
      if (typeof aSourceMap === "string") {
        sourceMap = util.parseSourceMapInput(aSourceMap);
      }
      return sourceMap.sections != null ? new IndexedSourceMapConsumer(sourceMap, aSourceMapURL) : new BasicSourceMapConsumer(sourceMap, aSourceMapURL);
    }
    SourceMapConsumer2.fromSourceMap = function(aSourceMap, aSourceMapURL) {
      return BasicSourceMapConsumer.fromSourceMap(aSourceMap, aSourceMapURL);
    };
    SourceMapConsumer2.prototype._version = 3;
    SourceMapConsumer2.prototype.__generatedMappings = null;
    Object.defineProperty(SourceMapConsumer2.prototype, "_generatedMappings", {
      configurable: true,
      enumerable: true,
      get: function() {
        if (!this.__generatedMappings) {
          this._parseMappings(this._mappings, this.sourceRoot);
        }
        return this.__generatedMappings;
      }
    });
    SourceMapConsumer2.prototype.__originalMappings = null;
    Object.defineProperty(SourceMapConsumer2.prototype, "_originalMappings", {
      configurable: true,
      enumerable: true,
      get: function() {
        if (!this.__originalMappings) {
          this._parseMappings(this._mappings, this.sourceRoot);
        }
        return this.__originalMappings;
      }
    });
    SourceMapConsumer2.prototype._charIsMappingSeparator = function SourceMapConsumer_charIsMappingSeparator(aStr, index) {
      var c = aStr.charAt(index);
      return c === ";" || c === ",";
    };
    SourceMapConsumer2.prototype._parseMappings = function SourceMapConsumer_parseMappings(aStr, aSourceRoot) {
      throw new Error("Subclasses must implement _parseMappings");
    };
    SourceMapConsumer2.GENERATED_ORDER = 1;
    SourceMapConsumer2.ORIGINAL_ORDER = 2;
    SourceMapConsumer2.GREATEST_LOWER_BOUND = 1;
    SourceMapConsumer2.LEAST_UPPER_BOUND = 2;
    SourceMapConsumer2.prototype.eachMapping = function SourceMapConsumer_eachMapping(aCallback, aContext, aOrder) {
      var context = aContext || null;
      var order = aOrder || SourceMapConsumer2.GENERATED_ORDER;
      var mappings;
      switch (order) {
        case SourceMapConsumer2.GENERATED_ORDER:
          mappings = this._generatedMappings;
          break;
        case SourceMapConsumer2.ORIGINAL_ORDER:
          mappings = this._originalMappings;
          break;
        default:
          throw new Error("Unknown order of iteration.");
      }
      var sourceRoot = this.sourceRoot;
      var boundCallback = aCallback.bind(context);
      var names = this._names;
      var sources = this._sources;
      var sourceMapURL = this._sourceMapURL;
      for (var i = 0, n = mappings.length; i < n; i++) {
        var mapping = mappings[i];
        var source = mapping.source === null ? null : sources.at(mapping.source);
        if (source !== null) {
          source = util.computeSourceURL(sourceRoot, source, sourceMapURL);
        }
        boundCallback({
          source,
          generatedLine: mapping.generatedLine,
          generatedColumn: mapping.generatedColumn,
          originalLine: mapping.originalLine,
          originalColumn: mapping.originalColumn,
          name: mapping.name === null ? null : names.at(mapping.name)
        });
      }
    };
    SourceMapConsumer2.prototype.allGeneratedPositionsFor = function SourceMapConsumer_allGeneratedPositionsFor(aArgs) {
      var line = util.getArg(aArgs, "line");
      var needle = {
        source: util.getArg(aArgs, "source"),
        originalLine: line,
        originalColumn: util.getArg(aArgs, "column", 0)
      };
      needle.source = this._findSourceIndex(needle.source);
      if (needle.source < 0) {
        return [];
      }
      var mappings = [];
      var index = this._findMapping(
        needle,
        this._originalMappings,
        "originalLine",
        "originalColumn",
        util.compareByOriginalPositions,
        binarySearch.LEAST_UPPER_BOUND
      );
      if (index >= 0) {
        var mapping = this._originalMappings[index];
        if (aArgs.column === void 0) {
          var originalLine = mapping.originalLine;
          while (mapping && mapping.originalLine === originalLine) {
            mappings.push({
              line: util.getArg(mapping, "generatedLine", null),
              column: util.getArg(mapping, "generatedColumn", null),
              lastColumn: util.getArg(mapping, "lastGeneratedColumn", null)
            });
            mapping = this._originalMappings[++index];
          }
        } else {
          var originalColumn = mapping.originalColumn;
          while (mapping && mapping.originalLine === line && mapping.originalColumn == originalColumn) {
            mappings.push({
              line: util.getArg(mapping, "generatedLine", null),
              column: util.getArg(mapping, "generatedColumn", null),
              lastColumn: util.getArg(mapping, "lastGeneratedColumn", null)
            });
            mapping = this._originalMappings[++index];
          }
        }
      }
      return mappings;
    };
    exports.SourceMapConsumer = SourceMapConsumer2;
    function BasicSourceMapConsumer(aSourceMap, aSourceMapURL) {
      var sourceMap = aSourceMap;
      if (typeof aSourceMap === "string") {
        sourceMap = util.parseSourceMapInput(aSourceMap);
      }
      var version = util.getArg(sourceMap, "version");
      var sources = util.getArg(sourceMap, "sources");
      var names = util.getArg(sourceMap, "names", []);
      var sourceRoot = util.getArg(sourceMap, "sourceRoot", null);
      var sourcesContent = util.getArg(sourceMap, "sourcesContent", null);
      var mappings = util.getArg(sourceMap, "mappings");
      var file = util.getArg(sourceMap, "file", null);
      if (version != this._version) {
        throw new Error("Unsupported version: " + version);
      }
      if (sourceRoot) {
        sourceRoot = util.normalize(sourceRoot);
      }
      sources = sources.map(String).map(util.normalize).map(function(source) {
        return sourceRoot && util.isAbsolute(sourceRoot) && util.isAbsolute(source) ? util.relative(sourceRoot, source) : source;
      });
      this._names = ArraySet.fromArray(names.map(String), true);
      this._sources = ArraySet.fromArray(sources, true);
      this._absoluteSources = this._sources.toArray().map(function(s) {
        return util.computeSourceURL(sourceRoot, s, aSourceMapURL);
      });
      this.sourceRoot = sourceRoot;
      this.sourcesContent = sourcesContent;
      this._mappings = mappings;
      this._sourceMapURL = aSourceMapURL;
      this.file = file;
    }
    BasicSourceMapConsumer.prototype = Object.create(SourceMapConsumer2.prototype);
    BasicSourceMapConsumer.prototype.consumer = SourceMapConsumer2;
    BasicSourceMapConsumer.prototype._findSourceIndex = function(aSource) {
      var relativeSource = aSource;
      if (this.sourceRoot != null) {
        relativeSource = util.relative(this.sourceRoot, relativeSource);
      }
      if (this._sources.has(relativeSource)) {
        return this._sources.indexOf(relativeSource);
      }
      var i;
      for (i = 0; i < this._absoluteSources.length; ++i) {
        if (this._absoluteSources[i] == aSource) {
          return i;
        }
      }
      return -1;
    };
    BasicSourceMapConsumer.fromSourceMap = function SourceMapConsumer_fromSourceMap(aSourceMap, aSourceMapURL) {
      var smc = Object.create(BasicSourceMapConsumer.prototype);
      var names = smc._names = ArraySet.fromArray(aSourceMap._names.toArray(), true);
      var sources = smc._sources = ArraySet.fromArray(aSourceMap._sources.toArray(), true);
      smc.sourceRoot = aSourceMap._sourceRoot;
      smc.sourcesContent = aSourceMap._generateSourcesContent(
        smc._sources.toArray(),
        smc.sourceRoot
      );
      smc.file = aSourceMap._file;
      smc._sourceMapURL = aSourceMapURL;
      smc._absoluteSources = smc._sources.toArray().map(function(s) {
        return util.computeSourceURL(smc.sourceRoot, s, aSourceMapURL);
      });
      var generatedMappings = aSourceMap._mappings.toArray().slice();
      var destGeneratedMappings = smc.__generatedMappings = [];
      var destOriginalMappings = smc.__originalMappings = [];
      for (var i = 0, length = generatedMappings.length; i < length; i++) {
        var srcMapping = generatedMappings[i];
        var destMapping = new Mapping();
        destMapping.generatedLine = srcMapping.generatedLine;
        destMapping.generatedColumn = srcMapping.generatedColumn;
        if (srcMapping.source) {
          destMapping.source = sources.indexOf(srcMapping.source);
          destMapping.originalLine = srcMapping.originalLine;
          destMapping.originalColumn = srcMapping.originalColumn;
          if (srcMapping.name) {
            destMapping.name = names.indexOf(srcMapping.name);
          }
          destOriginalMappings.push(destMapping);
        }
        destGeneratedMappings.push(destMapping);
      }
      quickSort(smc.__originalMappings, util.compareByOriginalPositions);
      return smc;
    };
    BasicSourceMapConsumer.prototype._version = 3;
    Object.defineProperty(BasicSourceMapConsumer.prototype, "sources", {
      get: function() {
        return this._absoluteSources.slice();
      }
    });
    function Mapping() {
      this.generatedLine = 0;
      this.generatedColumn = 0;
      this.source = null;
      this.originalLine = null;
      this.originalColumn = null;
      this.name = null;
    }
    var compareGenerated = util.compareByGeneratedPositionsDeflatedNoLine;
    function sortGenerated(array, start) {
      let l = array.length;
      let n = array.length - start;
      if (n <= 1) {
        return;
      } else if (n == 2) {
        let a = array[start];
        let b = array[start + 1];
        if (compareGenerated(a, b) > 0) {
          array[start] = b;
          array[start + 1] = a;
        }
      } else if (n < 20) {
        for (let i = start; i < l; i++) {
          for (let j = i; j > start; j--) {
            let a = array[j - 1];
            let b = array[j];
            if (compareGenerated(a, b) <= 0) {
              break;
            }
            array[j - 1] = b;
            array[j] = a;
          }
        }
      } else {
        quickSort(array, compareGenerated, start);
      }
    }
    BasicSourceMapConsumer.prototype._parseMappings = function SourceMapConsumer_parseMappings(aStr, aSourceRoot) {
      var generatedLine = 1;
      var previousGeneratedColumn = 0;
      var previousOriginalLine = 0;
      var previousOriginalColumn = 0;
      var previousSource = 0;
      var previousName = 0;
      var length = aStr.length;
      var index = 0;
      var cachedSegments = {};
      var temp = {};
      var originalMappings = [];
      var generatedMappings = [];
      var mapping, str, segment, end, value;
      let subarrayStart = 0;
      while (index < length) {
        if (aStr.charAt(index) === ";") {
          generatedLine++;
          index++;
          previousGeneratedColumn = 0;
          sortGenerated(generatedMappings, subarrayStart);
          subarrayStart = generatedMappings.length;
        } else if (aStr.charAt(index) === ",") {
          index++;
        } else {
          mapping = new Mapping();
          mapping.generatedLine = generatedLine;
          for (end = index; end < length; end++) {
            if (this._charIsMappingSeparator(aStr, end)) {
              break;
            }
          }
          str = aStr.slice(index, end);
          segment = [];
          while (index < end) {
            base64VLQ.decode(aStr, index, temp);
            value = temp.value;
            index = temp.rest;
            segment.push(value);
          }
          if (segment.length === 2) {
            throw new Error("Found a source, but no line and column");
          }
          if (segment.length === 3) {
            throw new Error("Found a source and line, but no column");
          }
          mapping.generatedColumn = previousGeneratedColumn + segment[0];
          previousGeneratedColumn = mapping.generatedColumn;
          if (segment.length > 1) {
            mapping.source = previousSource + segment[1];
            previousSource += segment[1];
            mapping.originalLine = previousOriginalLine + segment[2];
            previousOriginalLine = mapping.originalLine;
            mapping.originalLine += 1;
            mapping.originalColumn = previousOriginalColumn + segment[3];
            previousOriginalColumn = mapping.originalColumn;
            if (segment.length > 4) {
              mapping.name = previousName + segment[4];
              previousName += segment[4];
            }
          }
          generatedMappings.push(mapping);
          if (typeof mapping.originalLine === "number") {
            let currentSource = mapping.source;
            while (originalMappings.length <= currentSource) {
              originalMappings.push(null);
            }
            if (originalMappings[currentSource] === null) {
              originalMappings[currentSource] = [];
            }
            originalMappings[currentSource].push(mapping);
          }
        }
      }
      sortGenerated(generatedMappings, subarrayStart);
      this.__generatedMappings = generatedMappings;
      for (var i = 0; i < originalMappings.length; i++) {
        if (originalMappings[i] != null) {
          quickSort(originalMappings[i], util.compareByOriginalPositionsNoSource);
        }
      }
      this.__originalMappings = [].concat(...originalMappings);
    };
    BasicSourceMapConsumer.prototype._findMapping = function SourceMapConsumer_findMapping(aNeedle, aMappings, aLineName, aColumnName, aComparator, aBias) {
      if (aNeedle[aLineName] <= 0) {
        throw new TypeError("Line must be greater than or equal to 1, got " + aNeedle[aLineName]);
      }
      if (aNeedle[aColumnName] < 0) {
        throw new TypeError("Column must be greater than or equal to 0, got " + aNeedle[aColumnName]);
      }
      return binarySearch.search(aNeedle, aMappings, aComparator, aBias);
    };
    BasicSourceMapConsumer.prototype.computeColumnSpans = function SourceMapConsumer_computeColumnSpans() {
      for (var index = 0; index < this._generatedMappings.length; ++index) {
        var mapping = this._generatedMappings[index];
        if (index + 1 < this._generatedMappings.length) {
          var nextMapping = this._generatedMappings[index + 1];
          if (mapping.generatedLine === nextMapping.generatedLine) {
            mapping.lastGeneratedColumn = nextMapping.generatedColumn - 1;
            continue;
          }
        }
        mapping.lastGeneratedColumn = Infinity;
      }
    };
    BasicSourceMapConsumer.prototype.originalPositionFor = function SourceMapConsumer_originalPositionFor(aArgs) {
      var needle = {
        generatedLine: util.getArg(aArgs, "line"),
        generatedColumn: util.getArg(aArgs, "column")
      };
      var index = this._findMapping(
        needle,
        this._generatedMappings,
        "generatedLine",
        "generatedColumn",
        util.compareByGeneratedPositionsDeflated,
        util.getArg(aArgs, "bias", SourceMapConsumer2.GREATEST_LOWER_BOUND)
      );
      if (index >= 0) {
        var mapping = this._generatedMappings[index];
        if (mapping.generatedLine === needle.generatedLine) {
          var source = util.getArg(mapping, "source", null);
          if (source !== null) {
            source = this._sources.at(source);
            source = util.computeSourceURL(this.sourceRoot, source, this._sourceMapURL);
          }
          var name = util.getArg(mapping, "name", null);
          if (name !== null) {
            name = this._names.at(name);
          }
          return {
            source,
            line: util.getArg(mapping, "originalLine", null),
            column: util.getArg(mapping, "originalColumn", null),
            name
          };
        }
      }
      return {
        source: null,
        line: null,
        column: null,
        name: null
      };
    };
    BasicSourceMapConsumer.prototype.hasContentsOfAllSources = function BasicSourceMapConsumer_hasContentsOfAllSources() {
      if (!this.sourcesContent) {
        return false;
      }
      return this.sourcesContent.length >= this._sources.size() && !this.sourcesContent.some(function(sc) {
        return sc == null;
      });
    };
    BasicSourceMapConsumer.prototype.sourceContentFor = function SourceMapConsumer_sourceContentFor(aSource, nullOnMissing) {
      if (!this.sourcesContent) {
        return null;
      }
      var index = this._findSourceIndex(aSource);
      if (index >= 0) {
        return this.sourcesContent[index];
      }
      var relativeSource = aSource;
      if (this.sourceRoot != null) {
        relativeSource = util.relative(this.sourceRoot, relativeSource);
      }
      var url;
      if (this.sourceRoot != null && (url = util.urlParse(this.sourceRoot))) {
        var fileUriAbsPath = relativeSource.replace(/^file:\/\//, "");
        if (url.scheme == "file" && this._sources.has(fileUriAbsPath)) {
          return this.sourcesContent[this._sources.indexOf(fileUriAbsPath)];
        }
        if ((!url.path || url.path == "/") && this._sources.has("/" + relativeSource)) {
          return this.sourcesContent[this._sources.indexOf("/" + relativeSource)];
        }
      }
      if (nullOnMissing) {
        return null;
      } else {
        throw new Error('"' + relativeSource + '" is not in the SourceMap.');
      }
    };
    BasicSourceMapConsumer.prototype.generatedPositionFor = function SourceMapConsumer_generatedPositionFor(aArgs) {
      var source = util.getArg(aArgs, "source");
      source = this._findSourceIndex(source);
      if (source < 0) {
        return {
          line: null,
          column: null,
          lastColumn: null
        };
      }
      var needle = {
        source,
        originalLine: util.getArg(aArgs, "line"),
        originalColumn: util.getArg(aArgs, "column")
      };
      var index = this._findMapping(
        needle,
        this._originalMappings,
        "originalLine",
        "originalColumn",
        util.compareByOriginalPositions,
        util.getArg(aArgs, "bias", SourceMapConsumer2.GREATEST_LOWER_BOUND)
      );
      if (index >= 0) {
        var mapping = this._originalMappings[index];
        if (mapping.source === needle.source) {
          return {
            line: util.getArg(mapping, "generatedLine", null),
            column: util.getArg(mapping, "generatedColumn", null),
            lastColumn: util.getArg(mapping, "lastGeneratedColumn", null)
          };
        }
      }
      return {
        line: null,
        column: null,
        lastColumn: null
      };
    };
    exports.BasicSourceMapConsumer = BasicSourceMapConsumer;
    function IndexedSourceMapConsumer(aSourceMap, aSourceMapURL) {
      var sourceMap = aSourceMap;
      if (typeof aSourceMap === "string") {
        sourceMap = util.parseSourceMapInput(aSourceMap);
      }
      var version = util.getArg(sourceMap, "version");
      var sections = util.getArg(sourceMap, "sections");
      if (version != this._version) {
        throw new Error("Unsupported version: " + version);
      }
      this._sources = new ArraySet();
      this._names = new ArraySet();
      var lastOffset = {
        line: -1,
        column: 0
      };
      this._sections = sections.map(function(s) {
        if (s.url) {
          throw new Error("Support for url field in sections not implemented.");
        }
        var offset = util.getArg(s, "offset");
        var offsetLine = util.getArg(offset, "line");
        var offsetColumn = util.getArg(offset, "column");
        if (offsetLine < lastOffset.line || offsetLine === lastOffset.line && offsetColumn < lastOffset.column) {
          throw new Error("Section offsets must be ordered and non-overlapping.");
        }
        lastOffset = offset;
        return {
          generatedOffset: {
            // The offset fields are 0-based, but we use 1-based indices when
            // encoding/decoding from VLQ.
            generatedLine: offsetLine + 1,
            generatedColumn: offsetColumn + 1
          },
          consumer: new SourceMapConsumer2(util.getArg(s, "map"), aSourceMapURL)
        };
      });
    }
    IndexedSourceMapConsumer.prototype = Object.create(SourceMapConsumer2.prototype);
    IndexedSourceMapConsumer.prototype.constructor = SourceMapConsumer2;
    IndexedSourceMapConsumer.prototype._version = 3;
    Object.defineProperty(IndexedSourceMapConsumer.prototype, "sources", {
      get: function() {
        var sources = [];
        for (var i = 0; i < this._sections.length; i++) {
          for (var j = 0; j < this._sections[i].consumer.sources.length; j++) {
            sources.push(this._sections[i].consumer.sources[j]);
          }
        }
        return sources;
      }
    });
    IndexedSourceMapConsumer.prototype.originalPositionFor = function IndexedSourceMapConsumer_originalPositionFor(aArgs) {
      var needle = {
        generatedLine: util.getArg(aArgs, "line"),
        generatedColumn: util.getArg(aArgs, "column")
      };
      var sectionIndex = binarySearch.search(
        needle,
        this._sections,
        function(needle2, section2) {
          var cmp = needle2.generatedLine - section2.generatedOffset.generatedLine;
          if (cmp) {
            return cmp;
          }
          return needle2.generatedColumn - section2.generatedOffset.generatedColumn;
        }
      );
      var section = this._sections[sectionIndex];
      if (!section) {
        return {
          source: null,
          line: null,
          column: null,
          name: null
        };
      }
      return section.consumer.originalPositionFor({
        line: needle.generatedLine - (section.generatedOffset.generatedLine - 1),
        column: needle.generatedColumn - (section.generatedOffset.generatedLine === needle.generatedLine ? section.generatedOffset.generatedColumn - 1 : 0),
        bias: aArgs.bias
      });
    };
    IndexedSourceMapConsumer.prototype.hasContentsOfAllSources = function IndexedSourceMapConsumer_hasContentsOfAllSources() {
      return this._sections.every(function(s) {
        return s.consumer.hasContentsOfAllSources();
      });
    };
    IndexedSourceMapConsumer.prototype.sourceContentFor = function IndexedSourceMapConsumer_sourceContentFor(aSource, nullOnMissing) {
      for (var i = 0; i < this._sections.length; i++) {
        var section = this._sections[i];
        var content = section.consumer.sourceContentFor(aSource, true);
        if (content || content === "") {
          return content;
        }
      }
      if (nullOnMissing) {
        return null;
      } else {
        throw new Error('"' + aSource + '" is not in the SourceMap.');
      }
    };
    IndexedSourceMapConsumer.prototype.generatedPositionFor = function IndexedSourceMapConsumer_generatedPositionFor(aArgs) {
      for (var i = 0; i < this._sections.length; i++) {
        var section = this._sections[i];
        if (section.consumer._findSourceIndex(util.getArg(aArgs, "source")) === -1) {
          continue;
        }
        var generatedPosition = section.consumer.generatedPositionFor(aArgs);
        if (generatedPosition) {
          var ret = {
            line: generatedPosition.line + (section.generatedOffset.generatedLine - 1),
            column: generatedPosition.column + (section.generatedOffset.generatedLine === generatedPosition.line ? section.generatedOffset.generatedColumn - 1 : 0)
          };
          return ret;
        }
      }
      return {
        line: null,
        column: null
      };
    };
    IndexedSourceMapConsumer.prototype._parseMappings = function IndexedSourceMapConsumer_parseMappings(aStr, aSourceRoot) {
      this.__generatedMappings = [];
      this.__originalMappings = [];
      for (var i = 0; i < this._sections.length; i++) {
        var section = this._sections[i];
        var sectionMappings = section.consumer._generatedMappings;
        for (var j = 0; j < sectionMappings.length; j++) {
          var mapping = sectionMappings[j];
          var source = section.consumer._sources.at(mapping.source);
          if (source !== null) {
            source = util.computeSourceURL(section.consumer.sourceRoot, source, this._sourceMapURL);
          }
          this._sources.add(source);
          source = this._sources.indexOf(source);
          var name = null;
          if (mapping.name) {
            name = section.consumer._names.at(mapping.name);
            this._names.add(name);
            name = this._names.indexOf(name);
          }
          var adjustedMapping = {
            source,
            generatedLine: mapping.generatedLine + (section.generatedOffset.generatedLine - 1),
            generatedColumn: mapping.generatedColumn + (section.generatedOffset.generatedLine === mapping.generatedLine ? section.generatedOffset.generatedColumn - 1 : 0),
            originalLine: mapping.originalLine,
            originalColumn: mapping.originalColumn,
            name
          };
          this.__generatedMappings.push(adjustedMapping);
          if (typeof adjustedMapping.originalLine === "number") {
            this.__originalMappings.push(adjustedMapping);
          }
        }
      }
      quickSort(this.__generatedMappings, util.compareByGeneratedPositionsDeflated);
      quickSort(this.__originalMappings, util.compareByOriginalPositions);
    };
    exports.IndexedSourceMapConsumer = IndexedSourceMapConsumer;
  }
});

// node_modules/source-map-js/lib/source-node.js
var require_source_node = __commonJS({
  "node_modules/source-map-js/lib/source-node.js"(exports) {
    var SourceMapGenerator = require_source_map_generator().SourceMapGenerator;
    var util = require_util();
    var REGEX_NEWLINE = /(\r?\n)/;
    var NEWLINE_CODE = 10;
    var isSourceNode = "$$$isSourceNode$$$";
    function SourceNode(aLine, aColumn, aSource, aChunks, aName) {
      this.children = [];
      this.sourceContents = {};
      this.line = aLine == null ? null : aLine;
      this.column = aColumn == null ? null : aColumn;
      this.source = aSource == null ? null : aSource;
      this.name = aName == null ? null : aName;
      this[isSourceNode] = true;
      if (aChunks != null) this.add(aChunks);
    }
    SourceNode.fromStringWithSourceMap = function SourceNode_fromStringWithSourceMap(aGeneratedCode, aSourceMapConsumer, aRelativePath) {
      var node = new SourceNode();
      var remainingLines = aGeneratedCode.split(REGEX_NEWLINE);
      var remainingLinesIndex = 0;
      var shiftNextLine = function() {
        var lineContents = getNextLine();
        var newLine = getNextLine() || "";
        return lineContents + newLine;
        function getNextLine() {
          return remainingLinesIndex < remainingLines.length ? remainingLines[remainingLinesIndex++] : void 0;
        }
      };
      var lastGeneratedLine = 1, lastGeneratedColumn = 0;
      var lastMapping = null;
      aSourceMapConsumer.eachMapping(function(mapping) {
        if (lastMapping !== null) {
          if (lastGeneratedLine < mapping.generatedLine) {
            addMappingWithCode(lastMapping, shiftNextLine());
            lastGeneratedLine++;
            lastGeneratedColumn = 0;
          } else {
            var nextLine = remainingLines[remainingLinesIndex] || "";
            var code = nextLine.substr(0, mapping.generatedColumn - lastGeneratedColumn);
            remainingLines[remainingLinesIndex] = nextLine.substr(mapping.generatedColumn - lastGeneratedColumn);
            lastGeneratedColumn = mapping.generatedColumn;
            addMappingWithCode(lastMapping, code);
            lastMapping = mapping;
            return;
          }
        }
        while (lastGeneratedLine < mapping.generatedLine) {
          node.add(shiftNextLine());
          lastGeneratedLine++;
        }
        if (lastGeneratedColumn < mapping.generatedColumn) {
          var nextLine = remainingLines[remainingLinesIndex] || "";
          node.add(nextLine.substr(0, mapping.generatedColumn));
          remainingLines[remainingLinesIndex] = nextLine.substr(mapping.generatedColumn);
          lastGeneratedColumn = mapping.generatedColumn;
        }
        lastMapping = mapping;
      }, this);
      if (remainingLinesIndex < remainingLines.length) {
        if (lastMapping) {
          addMappingWithCode(lastMapping, shiftNextLine());
        }
        node.add(remainingLines.splice(remainingLinesIndex).join(""));
      }
      aSourceMapConsumer.sources.forEach(function(sourceFile) {
        var content = aSourceMapConsumer.sourceContentFor(sourceFile);
        if (content != null) {
          if (aRelativePath != null) {
            sourceFile = util.join(aRelativePath, sourceFile);
          }
          node.setSourceContent(sourceFile, content);
        }
      });
      return node;
      function addMappingWithCode(mapping, code) {
        if (mapping === null || mapping.source === void 0) {
          node.add(code);
        } else {
          var source = aRelativePath ? util.join(aRelativePath, mapping.source) : mapping.source;
          node.add(new SourceNode(
            mapping.originalLine,
            mapping.originalColumn,
            source,
            code,
            mapping.name
          ));
        }
      }
    };
    SourceNode.prototype.add = function SourceNode_add(aChunk) {
      if (Array.isArray(aChunk)) {
        aChunk.forEach(function(chunk) {
          this.add(chunk);
        }, this);
      } else if (aChunk[isSourceNode] || typeof aChunk === "string") {
        if (aChunk) {
          this.children.push(aChunk);
        }
      } else {
        throw new TypeError(
          "Expected a SourceNode, string, or an array of SourceNodes and strings. Got " + aChunk
        );
      }
      return this;
    };
    SourceNode.prototype.prepend = function SourceNode_prepend(aChunk) {
      if (Array.isArray(aChunk)) {
        for (var i = aChunk.length - 1; i >= 0; i--) {
          this.prepend(aChunk[i]);
        }
      } else if (aChunk[isSourceNode] || typeof aChunk === "string") {
        this.children.unshift(aChunk);
      } else {
        throw new TypeError(
          "Expected a SourceNode, string, or an array of SourceNodes and strings. Got " + aChunk
        );
      }
      return this;
    };
    SourceNode.prototype.walk = function SourceNode_walk(aFn) {
      var chunk;
      for (var i = 0, len = this.children.length; i < len; i++) {
        chunk = this.children[i];
        if (chunk[isSourceNode]) {
          chunk.walk(aFn);
        } else {
          if (chunk !== "") {
            aFn(chunk, {
              source: this.source,
              line: this.line,
              column: this.column,
              name: this.name
            });
          }
        }
      }
    };
    SourceNode.prototype.join = function SourceNode_join(aSep) {
      var newChildren;
      var i;
      var len = this.children.length;
      if (len > 0) {
        newChildren = [];
        for (i = 0; i < len - 1; i++) {
          newChildren.push(this.children[i]);
          newChildren.push(aSep);
        }
        newChildren.push(this.children[i]);
        this.children = newChildren;
      }
      return this;
    };
    SourceNode.prototype.replaceRight = function SourceNode_replaceRight(aPattern, aReplacement) {
      var lastChild = this.children[this.children.length - 1];
      if (lastChild[isSourceNode]) {
        lastChild.replaceRight(aPattern, aReplacement);
      } else if (typeof lastChild === "string") {
        this.children[this.children.length - 1] = lastChild.replace(aPattern, aReplacement);
      } else {
        this.children.push("".replace(aPattern, aReplacement));
      }
      return this;
    };
    SourceNode.prototype.setSourceContent = function SourceNode_setSourceContent(aSourceFile, aSourceContent) {
      this.sourceContents[util.toSetString(aSourceFile)] = aSourceContent;
    };
    SourceNode.prototype.walkSourceContents = function SourceNode_walkSourceContents(aFn) {
      for (var i = 0, len = this.children.length; i < len; i++) {
        if (this.children[i][isSourceNode]) {
          this.children[i].walkSourceContents(aFn);
        }
      }
      var sources = Object.keys(this.sourceContents);
      for (var i = 0, len = sources.length; i < len; i++) {
        aFn(util.fromSetString(sources[i]), this.sourceContents[sources[i]]);
      }
    };
    SourceNode.prototype.toString = function SourceNode_toString() {
      var str = "";
      this.walk(function(chunk) {
        str += chunk;
      });
      return str;
    };
    SourceNode.prototype.toStringWithSourceMap = function SourceNode_toStringWithSourceMap(aArgs) {
      var generated = {
        code: "",
        line: 1,
        column: 0
      };
      var map = new SourceMapGenerator(aArgs);
      var sourceMappingActive = false;
      var lastOriginalSource = null;
      var lastOriginalLine = null;
      var lastOriginalColumn = null;
      var lastOriginalName = null;
      this.walk(function(chunk, original) {
        generated.code += chunk;
        if (original.source !== null && original.line !== null && original.column !== null) {
          if (lastOriginalSource !== original.source || lastOriginalLine !== original.line || lastOriginalColumn !== original.column || lastOriginalName !== original.name) {
            map.addMapping({
              source: original.source,
              original: {
                line: original.line,
                column: original.column
              },
              generated: {
                line: generated.line,
                column: generated.column
              },
              name: original.name
            });
          }
          lastOriginalSource = original.source;
          lastOriginalLine = original.line;
          lastOriginalColumn = original.column;
          lastOriginalName = original.name;
          sourceMappingActive = true;
        } else if (sourceMappingActive) {
          map.addMapping({
            generated: {
              line: generated.line,
              column: generated.column
            }
          });
          lastOriginalSource = null;
          sourceMappingActive = false;
        }
        for (var idx = 0, length = chunk.length; idx < length; idx++) {
          if (chunk.charCodeAt(idx) === NEWLINE_CODE) {
            generated.line++;
            generated.column = 0;
            if (idx + 1 === length) {
              lastOriginalSource = null;
              sourceMappingActive = false;
            } else if (sourceMappingActive) {
              map.addMapping({
                source: original.source,
                original: {
                  line: original.line,
                  column: original.column
                },
                generated: {
                  line: generated.line,
                  column: generated.column
                },
                name: original.name
              });
            }
          } else {
            generated.column++;
          }
        }
      });
      this.walkSourceContents(function(sourceFile, sourceContent) {
        map.setSourceContent(sourceFile, sourceContent);
      });
      return { code: generated.code, map };
    };
    exports.SourceNode = SourceNode;
  }
});

// node_modules/source-map-js/source-map.js
var require_source_map = __commonJS({
  "node_modules/source-map-js/source-map.js"(exports) {
    exports.SourceMapGenerator = require_source_map_generator().SourceMapGenerator;
    exports.SourceMapConsumer = require_source_map_consumer().SourceMapConsumer;
    exports.SourceNode = require_source_node().SourceNode;
  }
});

// app/javascript/error_handler.ts
var import_source_map_js = __toESM(require_source_map());
var ERROR_TYPE_CONFIGS = {
  javascript: {
    icon: "\u26A0\uFE0F",
    fields: {
      filename: {
        label: "File",
        priority: 10,
        htmlFormatter: (value) => `<div class="my-1"><strong>File:</strong> ${value}</div>`,
        textFormatter: (value) => `File: ${value}`
      },
      lineno: {
        label: "Line",
        priority: 9,
        htmlFormatter: (value) => `<div class="mb-1"><strong>Line:</strong> ${value}</div>`,
        textFormatter: (value) => `Line: ${value}`
      },
      "error.stack": {
        label: "Stack Trace",
        priority: 1,
        condition: (error) => error.error?.stack,
        htmlFormatter: (value) => {
          const preClass = "text-xs bg-gray-800 p-3 rounded overflow-x-auto whitespace-pre-wrap leading-relaxed";
          return `<div class=""><div class="mb-1"><strong>Stack Trace:</strong></div><pre class="${preClass}">${value}</pre></div>`;
        },
        textFormatter: (value) => `Stack Trace:
${value}`
      }
    }
  },
  interaction: {
    icon: "\u{1F534}",
    fields: {
      filename: {
        label: "File",
        priority: 10,
        htmlFormatter: (value) => `<div class="mb-1"><strong>File:</strong> ${value}</div>`,
        textFormatter: (value) => `File: ${value}`
      },
      lineno: {
        label: "Line",
        priority: 9,
        htmlFormatter: (value) => `<div class="mb-1"><strong>Line:</strong> ${value}</div>`,
        textFormatter: (value) => `Line: ${value}`
      }
    }
  },
  http: {
    icon: "\u{1F310}",
    fields: {
      method: {
        label: "Method",
        priority: 10,
        htmlFormatter: (value) => `<div class="mb-1"><strong>Method:</strong> ${value}</div>`,
        textFormatter: (value) => `Method: ${value}`
      },
      status: {
        label: "Status Code",
        priority: 9,
        htmlFormatter: (value) => `<div class="mb-1"><strong>Status Code:</strong> ${value}</div>`,
        textFormatter: (value) => `Status Code: ${value}`
      },
      jsonError: {
        label: "JSON Error Details",
        priority: 5,
        condition: (error) => !!error.jsonError,
        htmlFormatter: (value) => {
          const preClass = "text-xs bg-gray-800 p-3 rounded overflow-x-auto whitespace-pre-wrap leading-relaxed";
          return `<div class="mb-3"><div class="mb-1"><strong>JSON Error Details:</strong></div><pre class="${preClass}">${JSON.stringify(value, null, 2)}</pre></div>`;
        },
        textFormatter: (value) => `JSON Error Details:
${JSON.stringify(value, null, 2)}`
      }
    }
  },
  promise: {
    icon: "\u26A1",
    fields: {
      "error.stack": {
        label: "Stack Trace",
        priority: 1,
        condition: (error) => error.error?.stack,
        htmlFormatter: (value) => {
          const preClass = "text-xs bg-gray-800 p-3 rounded overflow-x-auto whitespace-pre-wrap leading-relaxed";
          return `<div class="mb-3"><div class="mb-1"><strong>Stack Trace:</strong></div><pre class="${preClass}">${value}</pre></div>`;
        },
        textFormatter: (value) => `Stack Trace:
${value}`
      }
    }
  },
  actioncable: {
    icon: "\u{1F50C}",
    fields: {
      channel: {
        label: "Channel",
        priority: 10,
        htmlFormatter: (value) => `<div class="mb-1"><strong>Channel:</strong> ${value}</div>`,
        textFormatter: (value) => `Channel: ${value}`
      },
      action: {
        label: "Action",
        priority: 9,
        htmlFormatter: (value) => `<div class="mb-1"><strong>Action:</strong> ${value}</div>`,
        textFormatter: (value) => `Action: ${value}`
      },
      details: {
        label: "Channel Error Details",
        priority: 5,
        condition: (error) => !!error.details,
        htmlFormatter: (value) => {
          const preClass = "text-xs bg-gray-800 p-3 rounded overflow-x-auto whitespace-pre-wrap leading-relaxed";
          return `<div class="mb-3"><div class="mb-1"><strong>Channel Error Details:</strong></div><pre class="${preClass}">${JSON.stringify(value, null, 2)}</pre></div>`;
        },
        textFormatter: (value) => `Channel Error Details:
${JSON.stringify(value, null, 2)}`
      }
    }
  },
  stimulus: {
    icon: "\u{1F3AF}",
    fields: {
      subType: {
        label: "Stimulus Error Type",
        priority: 10,
        htmlFormatter: (value) => `<div class="mb-1"><strong>Stimulus Error Type:</strong> ${value}</div>`,
        textFormatter: (value) => `Stimulus Error Type: ${value}`
      },
      controllerName: {
        label: "Controller",
        priority: 9,
        htmlFormatter: (value) => `<div class="mb-1"><strong>Controller:</strong> ${value}</div>`,
        textFormatter: (value) => `Controller: ${value}`
      },
      action: {
        label: "Action",
        priority: 8,
        htmlFormatter: (value) => `<div class="mb-1"><strong>Action:</strong> ${value}</div>`,
        textFormatter: (value) => `Action: ${value}`
      },
      missingControllers: {
        label: "Missing Controllers",
        priority: 7,
        condition: (error) => !!(error.missingControllers && error.missingControllers.length > 0),
        htmlFormatter: (value) => `<div class="mb-3"><strong>Missing Controllers:</strong> ${value.join(", ")}</div>`,
        textFormatter: (value) => `Missing Controllers: ${value.join(", ")}`
      },
      positioningIssues: {
        label: "Positioning Issues",
        priority: 6,
        condition: (error) => !!(error.positioningIssues && error.positioningIssues.length > 0),
        htmlFormatter: (value) => {
          const ulClass = "text-xs list-disc list-inside bg-gray-800 p-3 rounded space-y-1";
          const items = value.map((issue) => `<li class="leading-relaxed">${issue}</li>`).join("");
          return `<div class="mb-3"><div class="mb-1"><strong>Positioning Issues:</strong></div><ul class="${ulClass}">${items}</ul></div>`;
        },
        textFormatter: (value) => `Positioning Issues:
${value.map((issue) => `  - ${issue}`).join("\n")}`
      },
      elementInfo: {
        label: "Element Info",
        priority: 5,
        condition: (error) => !!error.elementInfo,
        htmlFormatter: (value) => {
          const preClass = "text-xs bg-gray-800 p-3 rounded overflow-x-auto whitespace-pre-wrap leading-relaxed";
          return `<div class="mb-3"><div class="mb-1"><strong>Element Info:</strong></div><pre class="${preClass}">${JSON.stringify(value, null, 2)}</pre></div>`;
        },
        textFormatter: (value) => `Element Info:
${JSON.stringify(value, null, 2)}`
      },
      suggestion: {
        label: "\u{1F4A1} Suggestion",
        priority: 3,
        htmlFormatter: (value) => {
          const divClass = "text-sm bg-blue-900 text-blue-200 p-3 rounded leading-relaxed";
          return `<div class="mb-3"><div class="mb-1"><strong>\u{1F4A1} Suggestion:</strong></div><div class="${divClass}">${value}</div></div>`;
        },
        textFormatter: (value) => `Suggestion: ${value}`
      },
      details: {
        label: "Detailed Information",
        priority: 2,
        condition: (error) => !!error.details,
        htmlFormatter: (value) => {
          const preClass = "text-xs bg-gray-800 p-3 rounded overflow-x-auto whitespace-pre-wrap leading-relaxed";
          return `<div class="mb-3"><div class="mb-1"><strong>Detailed Information:</strong></div><pre class="${preClass}">${JSON.stringify(value, null, 2)}</pre></div>`;
        },
        textFormatter: (value) => `Detailed Information:
${JSON.stringify(value, null, 2)}`
      }
    }
  },
  asyncjob: {
    icon: "\u2699\uFE0F",
    fields: {
      job_class: {
        label: "Job Class",
        priority: 10,
        htmlFormatter: (value) => `<div class="mb-1"><strong>Job Class:</strong> ${value}</div>`,
        textFormatter: (value) => `Job Class: ${value}`
      },
      queue: {
        label: "Queue",
        priority: 9,
        htmlFormatter: (value) => `<div class="mb-1"><strong>Queue:</strong> ${value}</div>`,
        textFormatter: (value) => `Queue: ${value}`
      },
      exception_class: {
        label: "Exception",
        priority: 8,
        htmlFormatter: (value) => `<div class="mb-1"><strong>Exception:</strong> ${value}</div>`,
        textFormatter: (value) => `Exception: ${value}`
      },
      backtrace: {
        label: "Backtrace",
        priority: 5,
        condition: (error) => !!error.backtrace,
        htmlFormatter: (value) => {
          const preClass = "text-xs bg-gray-800 p-3 rounded overflow-x-auto whitespace-pre-wrap leading-relaxed";
          return `<div class="mb-3"><div class="mb-1"><strong>Backtrace:</strong></div><pre class="${preClass}">${value}</pre></div>`;
        },
        textFormatter: (value) => `Backtrace:
${value}`
      }
    }
  },
  manual: {
    icon: "\u{1F4DD}",
    fields: {
      // Manual errors can have dynamic fields, so we'll handle them in the generic formatter
    }
  }
};
var ErrorHandler = class {
  constructor() {
    this.errors = [];
    this.maxErrors = 50;
    this.isExpanded = false;
    this.statusBar = null;
    this.errorList = null;
    this.isInteractionError = false;
    this.errorCounts = {
      javascript: 0,
      interaction: 0,
      promise: 0,
      http: 0,
      actioncable: 0,
      asyncjob: 0,
      manual: 0,
      stimulus: 0
    };
    this.recentErrorsDebounce = /* @__PURE__ */ new Map();
    this.debounceTime = 1e3;
    this.uiReady = false;
    this.pendingUIUpdates = false;
    this.hasShownFirstError = false;
    this.lastInteractionTime = 0;
    this.sourceMapCache = /* @__PURE__ */ new Map();
    this.sourceMapPending = /* @__PURE__ */ new Map();
    this.lastUserAction = null;
    this.originalConsoleError = console.error.bind(console);
    this.init();
  }
  init() {
    this.setupGlobalErrorHandlers();
    this.setupInteractionTracking();
    this.setupTurboHandlers();
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", () => this.initUI());
    } else {
      this.initUI();
    }
  }
  setupTurboHandlers() {
    document.addEventListener("turbo:before-render", (event) => {
      if (this.statusBar && this.statusBar.parentNode) {
        this.statusBar.remove();
      }
    });
    document.addEventListener("turbo:render", () => {
      if (this.statusBar && !document.getElementById("js-error-status-bar")) {
        document.body.appendChild(this.statusBar);
      }
    });
  }
  initUI() {
    if (this.uiReady) {
      return;
    }
    console.log("[ErrorHandler] Initializing UI");
    this.createStatusBar();
    this.uiReady = true;
    this.updateStatusBar();
    if (this.pendingUIUpdates) {
      this.updateErrorList();
      this.showStatusBar();
      this.pendingUIUpdates = false;
    }
  }
  createStatusBar() {
    const statusBar = document.createElement("div");
    statusBar.id = "js-error-status-bar";
    statusBar.className = "fixed bottom-0 left-0 right-0 bg-gray-900 text-white z-50 border-t border-gray-700 transition-all duration-300";
    statusBar.style.display = "none";
    statusBar.innerHTML = `
      <div class="flex items-center justify-between px-4 py-2 h-10">
        <div class="flex items-center space-x-4">
          <div id="error-summary" class="flex items-center space-x-3 text-sm">
            <!-- Error counts will be inserted here -->
          </div>
          <div id="error-tips" class="relative" style="display: none;">
            <span class="cursor-help text-gray-500 hover:text-gray-300 transition-colors duration-200 text-sm opacity-60 hover:opacity-100">\u{1F4A1}</span>
            <div class="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 px-3 py-2 bg-gray-800 text-white text-xs
                      rounded-lg shadow-lg border border-gray-600 whitespace-nowrap opacity-0 pointer-events-none
                      transition-opacity duration-200 tooltip">
              Send to chatbox for repair (90% cases) or ignore if browser extension (10% cases)
              <div class="absolute top-full left-1/2 transform -translate-x-1/2 w-0 h-0 border-l-4 border-r-4 border-t-4
                        border-transparent border-t-gray-800"></div>
            </div>
          </div>
        </div>
        <div class="flex items-center space-x-2">
          <button id="copy-all-errors" class="text-yellow-400 hover:text-yellow-300 text-sm px-2 py-1 rounded" style="display: none;">
            Copy Error
          </button>
          <button id="toggle-errors" class="text-blue-400 hover:text-blue-300 text-sm px-2 py-1 rounded">
            <span id="toggle-text">Show</span>
            <span id="toggle-icon">\u2191</span>
          </button>
          <button id="clear-all-errors" class="text-red-400 hover:text-red-300 text-sm px-2 py-1 rounded">
            Clear
          </button>
        </div>
      </div>
      <div id="error-details" class="border-t border-gray-700 bg-gray-800 max-h-64 overflow-y-auto" style="display: none;">
        <div id="error-list" class="p-4 space-y-2">
          <!-- Error list will be inserted here -->
        </div>
      </div>
    `;
    document.body.appendChild(statusBar);
    this.statusBar = statusBar;
    this.errorList = document.getElementById("error-list");
    this.setupStatusBarEvents();
  }
  setupStatusBarEvents() {
    document.getElementById("toggle-errors")?.addEventListener("click", () => {
      this.toggleErrorDetails();
    });
    document.getElementById("copy-all-errors")?.addEventListener("click", () => {
      this.copyAllErrorsToClipboard();
    });
    document.getElementById("clear-all-errors")?.addEventListener("click", () => {
      this.clearAllErrors();
    });
    this.setupTooltipEvents();
  }
  setupTooltipEvents() {
    const tipsContainer = document.getElementById("error-tips");
    if (!tipsContainer) return;
    const icon = tipsContainer.querySelector("span");
    const tooltip = tipsContainer.querySelector(".tooltip");
    if (icon && tooltip) {
      icon.addEventListener("mouseenter", () => {
        tooltip.classList.remove("opacity-0", "pointer-events-none");
        tooltip.classList.add("opacity-100");
      });
      icon.addEventListener("mouseleave", () => {
        tooltip.classList.remove("opacity-100");
        tooltip.classList.add("opacity-0", "pointer-events-none");
      });
    }
  }
  toggleErrorDetails() {
    const details = document.getElementById("error-details");
    const toggleText = document.getElementById("toggle-text");
    const toggleIcon = document.getElementById("toggle-icon");
    if (!details || !toggleText || !toggleIcon) return;
    this.isExpanded = !this.isExpanded;
    if (this.isExpanded) {
      details.style.display = "block";
      toggleText.textContent = "Hide";
      toggleIcon.textContent = "\u2193";
    } else {
      details.style.display = "none";
      toggleText.textContent = "Show";
      toggleIcon.textContent = "\u2191";
    }
  }
  recordUserAction(eventType, event) {
    const target = event.target;
    if (!target) return;
    const elementParts = [target.tagName.toLowerCase()];
    if (target.id) {
      elementParts.push(`#${target.id}`);
    }
    if (target.className && typeof target.className === "string") {
      const classes = target.className.split(" ").filter((c) => c.trim());
      if (classes.length > 0) {
        elementParts.push(`.${classes.slice(0, 3).join(".")}`);
      }
    }
    const elementSelector = elementParts.join("");
    let text;
    if (eventType !== "change" && eventType !== "keydown") {
      const textContent = target.textContent?.trim() || "";
      if (textContent && textContent.length > 0) {
        text = textContent.substring(0, 50);
        if (textContent.length > 50) text += "...";
      }
    }
    const stimulusAction = target.getAttribute("data-action") || void 0;
    const stimulusController = target.getAttribute("data-controller") || void 0;
    let additionalInfo = "";
    if (target.tagName === "A") {
      const href = target.getAttribute("href");
      if (href) additionalInfo = ` href="${href}"`;
    } else if (target.tagName === "FORM") {
      const action = target.getAttribute("action");
      if (action) additionalInfo = ` action="${action}"`;
    }
    this.lastUserAction = {
      timestamp: Date.now(),
      type: eventType,
      element: elementSelector + additionalInfo,
      text,
      stimulusAction,
      stimulusController
    };
  }
  setupGlobalErrorHandlers() {
    console.error = (...args) => {
      this.originalConsoleError(...args);
      let message = "";
      if (args.length === 0) return;
      const firstArg = args[0];
      if (typeof firstArg === "string" && /%[sodifcO]/.test(firstArg)) {
        message = firstArg;
        let argIndex = 1;
        message = message.replace(/%[sodifcO]/g, (match) => {
          if (argIndex >= args.length) return match;
          const arg = args[argIndex++];
          if (arg instanceof Error) {
            return arg.message;
          } else if (typeof arg === "object") {
            try {
              return JSON.stringify(arg);
            } catch {
              return String(arg);
            }
          }
          return String(arg);
        });
      } else {
        message = args.map((arg) => {
          if (arg instanceof Error) {
            return arg.message;
          } else if (typeof arg === "object") {
            try {
              return JSON.stringify(arg);
            } catch {
              return String(arg);
            }
          }
          return String(arg);
        }).join(" ");
      }
      if (!message || message.trim().length === 0) {
        return;
      }
      const isDuplicate = this.errors.some((error) => {
        const existingMsg = error.message.replace(/^\[console\.error\]\s*/, "");
        const newMsg = message;
        const isSimilar = existingMsg.includes(newMsg) || newMsg.includes(existingMsg);
        const isRecent = Date.now() - new Date(error.lastOccurred).getTime() < 5e3;
        return isSimilar && isRecent;
      });
      if (!isDuplicate) {
        let errorObj = args.find((arg) => arg instanceof Error);
        if (!errorObj) {
          errorObj = new Error(message);
          if (errorObj.stack) {
            const stackLines = errorObj.stack.split("\n");
            errorObj.stack = [stackLines[0], ...stackLines.slice(3)].join("\n");
          }
        }
        this.handleError({
          message: `[console.error] ${message}`,
          type: "javascript",
          timestamp: (/* @__PURE__ */ new Date()).toISOString(),
          error: errorObj
        });
      }
    };
    if (!window.onerror) {
      window.onerror = (message, source, lineno, colno, error) => {
        this.originalConsoleError("\u{1F514} window.onerror triggered:", { message, source, lineno, colno, error });
        this.handleError({
          message: typeof message === "string" ? message : "Script error",
          filename: source,
          lineno,
          colno,
          error,
          type: this.isInteractionError ? "interaction" : "javascript",
          timestamp: (/* @__PURE__ */ new Date()).toISOString()
        });
        return true;
      };
    }
    window.addEventListener("error", (event) => {
      if (window.onerror && typeof window.onerror === "function") {
        return;
      }
      this.handleError({
        message: event.message,
        filename: event.filename,
        lineno: event.lineno,
        colno: event.colno,
        error: event.error,
        type: this.isInteractionError ? "interaction" : "javascript",
        timestamp: (/* @__PURE__ */ new Date()).toISOString()
      });
    });
    window.addEventListener("unhandledrejection", (event) => {
      this.handleError({
        message: event.reason?.message || "Unhandled Promise Rejection",
        error: event.reason,
        type: "promise",
        timestamp: (/* @__PURE__ */ new Date()).toISOString()
      });
    });
    this.interceptFetch();
    this.interceptXHR();
  }
  setupInteractionTracking() {
    ["click", "submit", "change", "keydown"].forEach((eventType) => {
      document.addEventListener(eventType, (event) => {
        this.isInteractionError = true;
        this.lastInteractionTime = Date.now();
        this.recordUserAction(eventType, event);
        setTimeout(() => {
          this.isInteractionError = false;
        }, 2e3);
      });
    });
    document.addEventListener("click", (event) => {
      const target = event.target;
      if (!target) return;
      const link = target.closest("a");
      if (!link) return;
      const href = link.getAttribute("href");
      if (!href || href === "#" || href === "#!" || href.startsWith("javascript:")) {
        if (link.hasAttribute("data-action")) {
          return;
        }
        this.handleError({
          message: `Clicked placeholder link with href="${href || "(empty)"}" - Use real Rails routes instead`,
          type: "interaction",
          timestamp: (/* @__PURE__ */ new Date()).toISOString(),
          filename: window.location.pathname,
          error: new Error(`Placeholder link detected: ${link.outerHTML.substring(0, 100)}`)
        });
      }
    }, true);
    document.addEventListener("submit", (event) => {
      const form = event.target;
      if (!form) return;
      const action = form.getAttribute("action");
      if (!action || action === "#" || action === "#!" || action.startsWith("javascript:")) {
        if (form.hasAttribute("data-action") || form.hasAttribute("data-turbo-stream")) {
          return;
        }
        this.handleError({
          message: `Submitted form with placeholder action="${action || "(empty)"}" - Use real Rails routes instead`,
          type: "interaction",
          timestamp: (/* @__PURE__ */ new Date()).toISOString(),
          filename: window.location.pathname,
          error: new Error(`Placeholder form action detected: ${form.outerHTML.substring(0, 100)}`)
        });
      }
    }, true);
  }
  interceptFetch() {
    const originalFetch = window.fetch;
    window.fetch = async (...args) => {
      const response = await originalFetch(...args);
      if (response.status >= 500) {
        const contentType = response.headers.get("content-type");
        const requestOptions = args[1] || {};
        const method = (requestOptions.method || "GET").toUpperCase();
        const shouldReport = response.status === 500 || contentType && contentType.includes("application/json");
        if (shouldReport) {
          let jsonError = null;
          try {
            const responseClone = response.clone();
            jsonError = await responseClone.json();
          } catch (bodyError) {
            jsonError = null;
          }
          let detailedMessage = `${method} ${args[0]} - HTTP ${response.status}`;
          if (jsonError) {
            const errorMsg = jsonError.error || jsonError.message || jsonError.errors || "Unknown error";
            detailedMessage += ` - ${errorMsg}`;
          }
          this.handleError({
            message: detailedMessage,
            url: args[0].toString(),
            method,
            type: "http",
            status: response.status,
            jsonError,
            timestamp: (/* @__PURE__ */ new Date()).toISOString()
          });
        }
      }
      return response;
    };
  }
  interceptXHR() {
    const originalXHROpen = XMLHttpRequest.prototype.open;
    const originalXHRSend = XMLHttpRequest.prototype.send;
    XMLHttpRequest.prototype.open = function(method, url, async, user, password) {
      this._errorHandler_method = method.toUpperCase();
      this._errorHandler_url = url.toString();
      return originalXHROpen.call(this, method, url, async ?? true, user, password);
    };
    XMLHttpRequest.prototype.send = function(body) {
      const xhr = this;
      const method = xhr._errorHandler_method || "GET";
      const url = xhr._errorHandler_url || "unknown";
      xhr.addEventListener("loadend", () => {
        if (xhr.status >= 500) {
          const contentType = xhr.getResponseHeader("content-type");
          const shouldReport = xhr.status === 500 || contentType && contentType.includes("application/json");
          if (shouldReport) {
            let jsonError = null;
            try {
              jsonError = JSON.parse(xhr.responseText);
            } catch (parseError) {
              jsonError = null;
            }
            let detailedMessage = `${method} ${url} - HTTP ${xhr.status}`;
            if (jsonError) {
              const errorMsg = jsonError.error || jsonError.message || jsonError.errors || "Unknown error";
              detailedMessage += ` - ${errorMsg}`;
            }
            window.errorHandler?.handleError({
              message: detailedMessage,
              url,
              method,
              type: "http",
              status: xhr.status,
              jsonError,
              timestamp: (/* @__PURE__ */ new Date()).toISOString()
            });
          }
        }
      });
      return originalXHRSend.call(this, body);
    };
  }
  handleError(errorInfo) {
    if (this.shouldIgnoreError(errorInfo)) {
      return;
    }
    this.enrichErrorWithSourceMap(errorInfo).then((enrichedError) => {
      this.processError(enrichedError);
    }).catch((err) => {
      this.originalConsoleError("Failed to enrich error with source map", err);
      this.processError(errorInfo);
    });
  }
  processError(errorInfo) {
    const debounceKey = `${errorInfo.type}_${errorInfo.message}_${errorInfo.filename}_${errorInfo.lineno}`;
    if (this.recentErrorsDebounce.has(debounceKey)) {
      const lastTime = this.recentErrorsDebounce.get(debounceKey);
      if (lastTime && Date.now() - lastTime < this.debounceTime) {
        const existingError = this.findDuplicateError(errorInfo);
        if (existingError) {
          existingError.count++;
          existingError.lastOccurred = errorInfo.timestamp;
          this.updateStatusBar();
          this.updateErrorList();
        }
        return;
      }
    }
    this.recentErrorsDebounce.set(debounceKey, Date.now());
    const isDuplicate = this.findDuplicateError(errorInfo);
    if (isDuplicate) {
      isDuplicate.count++;
      isDuplicate.lastOccurred = errorInfo.timestamp;
    } else {
      const error = {
        id: this.generateErrorId(),
        ...errorInfo,
        count: 1,
        lastOccurred: errorInfo.timestamp
      };
      this.errors.unshift(error);
      if (this.errors.length > this.maxErrors) {
        this.errors = this.errors.slice(0, this.maxErrors);
      }
    }
    if (errorInfo.type in this.errorCounts) {
      this.errorCounts[errorInfo.type]++;
    }
    if (this.uiReady) {
      this.updateStatusBar();
      this.updateErrorList();
      this.showStatusBar();
      this.flashNewError();
    } else {
      this.pendingUIUpdates = true;
    }
    this.cleanupDebounceMap();
  }
  shouldIgnoreError(errorInfo) {
    const ignoredPatterns = [
      // Browser extension errors
      /chrome-extension:/,
      /moz-extension:/,
      /safari-extension:/,
      // Common browser errors we can't control
      /Script error/,
      /Non-Error promise rejection captured/,
      /ResizeObserver loop/,
      /passive event listener/,
      // Turbo navigation aborted requests (normal behavior)
      /user aborted/i,
      /AbortError/,
      /request.*aborted/i,
      // Third-party script errors
      /google-analytics/,
      /googletagmanager/,
      /facebook\.net/,
      /twitter\.com/,
      // Preview/Debug SDKs
      /clacky-preview-sdk/,
      // iOS Safari specific
      /WebKitBlobResource/
    ];
    const message = errorInfo.message || "";
    const filename = errorInfo.filename || "";
    return ignoredPatterns.some(
      (pattern) => pattern.test(message) || pattern.test(filename)
    );
  }
  findDuplicateError(errorInfo) {
    return this.errors.find((error) => {
      const existingMsg = error.message.replace(/^\[console\.error\]\s*/, "");
      const newMsg = errorInfo.message.replace(/^\[console\.error\]\s*/, "");
      const messagesMatch = existingMsg.includes(newMsg) || newMsg.includes(existingMsg);
      if (!messagesMatch) return false;
      const typesMatch = error.type === errorInfo.type || error.type === "javascript" && errorInfo.type === "interaction" || error.type === "interaction" && errorInfo.type === "javascript";
      if (!typesMatch) return false;
      const bothHaveLocation = error.filename && errorInfo.filename;
      if (bothHaveLocation) {
        if (error.filename !== errorInfo.filename || error.lineno !== errorInfo.lineno) {
          return false;
        }
      }
      return true;
    });
  }
  generateErrorId() {
    return `error_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
  updateStatusBar() {
    const summary = document.getElementById("error-summary");
    const copyButton = document.getElementById("copy-all-errors");
    const tipsElement = document.getElementById("error-tips");
    if (!summary) return;
    const totalErrors = this.errors.reduce((sum, error) => sum + error.count, 0);
    if (totalErrors === 0) {
      summary.innerHTML = '<span class="text-green-400">\u2713 No Errors</span>';
      if (copyButton) copyButton.style.display = "none";
      if (tipsElement) tipsElement.style.display = "none";
      return;
    }
    summary.innerHTML = `<span class="text-red-400">\u{1F534} Frontend code error detected (${totalErrors})</span>`;
    if (copyButton) copyButton.style.display = "block";
    if (tipsElement) tipsElement.style.display = "block";
  }
  updateErrorList() {
    if (!this.errorList) return;
    const listHTML = this.errors.map((error) => this.createErrorItemHTML(error)).join("");
    this.errorList.innerHTML = listHTML;
    this.attachErrorItemListeners();
  }
  createErrorItemHTML(error) {
    const icon = this.getErrorIcon(error.type);
    const countText = error.count > 1 ? ` (${error.count}x)` : "";
    const timeStr = new Date(error.timestamp).toLocaleTimeString();
    return `
      <div class="flex items-start justify-between bg-gray-700 rounded p-3 error-item" data-error-id="${error.id}">
        <div class="flex items-start space-x-3 flex-1">
          <div class="text-lg">${icon}</div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center justify-between">
              <span class="font-medium text-sm text-white truncate pr-2">${this.sanitizeMessage(error.message)}</span>
              <span class="text-xs text-gray-400 whitespace-nowrap mt-1">${timeStr}${countText}</span>
            </div>
            <div class="technical-details mt-2 text-xs text-gray-500" style="display: none;">
              ${this.formatTechnicalDetails(error)}
            </div>
          </div>
        </div>
        <div class="flex items-center space-x-1 ml-3">
          <button class="copy-error text-blue-400 hover:text-blue-300 px-2 py-1 text-xs rounded" title="Copy error for chatbox">
            Copy
          </button>
          <button class="toggle-details text-gray-400 hover:text-gray-300 px-2 py-1 text-xs rounded" title="Toggle details">
            Details
          </button>
          <button class="close-error text-red-400 hover:text-red-300 px-2 py-1 text-xs rounded" title="Close">
            \xD7
          </button>
        </div>
      </div>
    `;
  }
  attachErrorItemListeners() {
    document.querySelectorAll(".copy-error").forEach((button) => {
      button.addEventListener("click", (e) => {
        const errorId = e.target.closest(".error-item")?.dataset.errorId;
        if (errorId) this.copyErrorToClipboard(errorId);
      });
    });
    document.querySelectorAll(".toggle-details").forEach((button) => {
      button.addEventListener("click", (e) => {
        const errorItem = e.target.closest(".error-item");
        const details = errorItem?.querySelector(".technical-details");
        const isVisible = details?.style.display !== "none";
        if (details) details.style.display = isVisible ? "none" : "block";
        e.target.textContent = isVisible ? "Details" : "Hide";
      });
    });
    document.querySelectorAll(".close-error").forEach((button) => {
      button.addEventListener("click", (e) => {
        const errorId = e.target.closest(".error-item")?.dataset.errorId;
        if (errorId) this.removeError(errorId);
      });
    });
  }
  getErrorIcon(type) {
    return ERROR_TYPE_CONFIGS[type]?.icon || "\u274C";
  }
  // Unified error detail formatting
  formatErrorDetails(error, format) {
    const config = ERROR_TYPE_CONFIGS[error.type];
    if (!config) {
      return this.formatGenericErrorDetails(error, format);
    }
    const details = [];
    const fields = Object.entries(config.fields);
    fields.sort(([, a], [, b]) => (b.priority || 0) - (a.priority || 0));
    for (const [fieldPath, fieldConfig] of fields) {
      if (fieldConfig.condition && !fieldConfig.condition(error)) {
        continue;
      }
      const value = this.getNestedValue(error, fieldPath);
      if (value !== void 0 && value !== null && value !== "") {
        const formatter = format === "html" ? fieldConfig.htmlFormatter : fieldConfig.textFormatter;
        details.push(formatter(value, fieldPath));
      }
    }
    return details;
  }
  // Helper to get nested object values using dot notation
  getNestedValue(obj, path) {
    return path.split(".").reduce((current, key) => current?.[key], obj);
  }
  // Fallback formatter for unknown error types or manual errors
  formatGenericErrorDetails(error, format) {
    const details = [];
    const commonFields = ["filename", "lineno", "colno", "stack"];
    for (const field of commonFields) {
      const value = error[field];
      if (value !== void 0 && value !== null && value !== "") {
        if (format === "html") {
          if (field === "stack") {
            const preClass = "text-xs bg-gray-800 p-3 rounded overflow-x-auto whitespace-pre-wrap leading-relaxed";
            details.push(`<div class="mb-3"><div class="mb-1"><strong>${this.capitalize(field)}:</strong></div><pre class="${preClass}">${value}</pre></div>`);
          } else {
            details.push(`<div class="mb-1"><strong>${this.capitalize(field)}:</strong> ${value}</div>`);
          }
        } else {
          details.push(`${this.capitalize(field)}: ${value}`);
        }
      }
    }
    if (error.type === "manual") {
      for (const [key, value] of Object.entries(error)) {
        const excludedFields = ["id", "message", "type", "timestamp", ...commonFields];
        if (!excludedFields.includes(key) && value !== void 0 && value !== null && value !== "") {
          if (format === "html") {
            const formattedValue = typeof value === "object" ? JSON.stringify(value, null, 2) : String(value);
            if (typeof value === "object") {
              const preClass = "text-xs bg-gray-800 p-3 rounded overflow-x-auto whitespace-pre-wrap leading-relaxed";
              details.push(`<div class="mb-3"><div class="mb-1"><strong>${this.capitalize(key)}:</strong></div><pre class="${preClass}">${formattedValue}</pre></div>`);
            } else {
              details.push(`<div class="mb-1"><strong>${this.capitalize(key)}:</strong> ${formattedValue}</div>`);
            }
          } else {
            const formattedValue = typeof value === "object" ? JSON.stringify(value, null, 2) : String(value);
            details.push(`${this.capitalize(key)}: ${formattedValue}`);
          }
        }
      }
    }
    return details;
  }
  // Helper to capitalize first letter
  capitalize(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
  }
  formatTechnicalDetails(error) {
    const details = [`<div class='mb-1'><strong>Page Path:</strong> ${window.location.pathname}</div>`];
    const typeSpecificDetails = this.formatErrorDetails(error, "html");
    details.push(...typeSpecificDetails);
    return details.join("");
  }
  copyErrorToClipboard(errorId) {
    const error = this.errors.find((e) => e.id === errorId);
    if (!error) return;
    const errorReport = this.generateErrorReport(error);
    const button = document.querySelector(`[data-error-id="${errorId}"] .copy-error`);
    if (!window.copyToClipboard) {
      this.originalConsoleError("window.copyToClipboard not found");
      alert(`Copy failed. Error details:
${errorReport}`);
      return;
    }
    window.copyToClipboard(errorReport).then(() => {
      if (!button) return;
      const originalText = button.textContent;
      button.textContent = "Copied";
      button.className = button.className.replace("text-blue-400", "text-green-400");
      setTimeout(() => {
        button.textContent = originalText;
        button.className = button.className.replace("text-green-400", "text-blue-400");
      }, 2e3);
    }).catch((err) => {
      this.originalConsoleError("Failed to copy error:", err);
      alert(`Copy failed. Error details:
${errorReport}`);
    });
  }
  copyAllErrorsToClipboard() {
    if (this.errors.length === 0) return;
    const allErrorsReport = this.generateAllErrorsReport();
    const button = document.getElementById("copy-all-errors");
    if (!window.copyToClipboard) {
      this.originalConsoleError("window.copyToClipboard not found");
      alert(`Copy failed. Error details:
${allErrorsReport}`);
      return;
    }
    window.copyToClipboard(allErrorsReport).then(() => {
      if (!button) return;
      const originalText = button.textContent;
      button.textContent = "Copied";
      button.className = button.className.replace("text-yellow-400", "text-green-400");
      setTimeout(() => {
        button.textContent = originalText;
        button.className = button.className.replace("text-green-400", "text-yellow-400");
      }, 2e3);
    }).catch((err) => {
      this.originalConsoleError("Failed to copy all errors:", err);
      alert(`Copy failed. Error details:
${allErrorsReport}`);
    });
  }
  generateAllErrorsReport() {
    const maxErrors = 3;
    const maxResponseBodyLength = 400;
    const maxTotalLength = 2e3;
    const recentErrors = this.errors.slice(0, maxErrors);
    const totalErrors = this.errors.reduce((sum, error) => sum + error.count, 0);
    let report = `Frontend Error Report - Recent Errors
\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550
Time: ${(/* @__PURE__ */ new Date()).toLocaleString()}
Page Path: ${window.location.pathname}
Total Errors: ${totalErrors} (showing latest ${recentErrors.length})
${this.formatLastUserAction()}
`;
    for (let index = 0; index < recentErrors.length; index++) {
      const error = recentErrors[index];
      const countText = error.count > 1 ? ` (${error.count}x)` : "";
      report += `Error ${index + 1}${countText}:
\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
${error.message}

Technical Details:`;
      const typeSpecificDetails = this.formatErrorDetails(error, "text");
      if (typeSpecificDetails.length > 0) {
        const truncatedDetails = typeSpecificDetails.map(
          (detail) => this.truncateText(detail, maxResponseBodyLength)
        );
        report += `
${truncatedDetails.join("\n")}`;
      }
      report += `
First occurred: ${new Date(error.timestamp).toLocaleString()}`;
      if (error.lastOccurred && error.lastOccurred !== error.timestamp) {
        report += `
Last occurred: ${new Date(error.lastOccurred).toLocaleString()}`;
      }
      report += "\n\n";
      if (report.length > maxTotalLength - 100) {
        report += `[Report truncated due to length limit]`;
        break;
      }
    }
    if (report.length > maxTotalLength - 50) {
      report = `${report.substring(0, maxTotalLength - 50)}...

`;
    }
    report += "Please help me analyze and fix these issues.";
    return report;
  }
  generateErrorReport(error) {
    const maxDetailLength = 800;
    const maxTotalLength = 3e3;
    let report = `Frontend Error Report
\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
Time: ${new Date(error.timestamp).toLocaleString()}
Page Path: ${window.location.pathname}
${this.formatLastUserAction()}
Technical Details:
${this.truncateText(error.message, maxDetailLength)}`;
    const typeSpecificDetails = this.formatErrorDetails(error, "text");
    if (typeSpecificDetails.length > 0) {
      const truncatedDetails = typeSpecificDetails.map(
        (detail) => this.truncateText(detail, maxDetailLength)
      );
      report += `

${truncatedDetails.join("\n")}`;
    }
    if (report.length > maxTotalLength - 100) {
      report = `${report.substring(0, maxTotalLength - 100)}...

[Report truncated due to length limit]`;
    }
    report += `

Please help me analyze and fix this issue.`;
    return report;
  }
  removeError(errorId) {
    const errorIndex = this.errors.findIndex((e) => e.id === errorId);
    if (errorIndex === -1) return;
    const error = this.errors[errorIndex];
    if (error.type in this.errorCounts) {
      this.errorCounts[error.type] = Math.max(0, (this.errorCounts[error.type] || 0) - error.count);
    }
    this.errors.splice(errorIndex, 1);
    this.updateStatusBar();
    this.updateErrorList();
    if (this.errors.length === 0) {
      this.hideStatusBar();
    }
  }
  clearAllErrors() {
    this.errors = [];
    this.errorCounts = {
      javascript: 0,
      interaction: 0,
      promise: 0,
      http: 0,
      actioncable: 0,
      asyncjob: 0,
      manual: 0,
      stimulus: 0
    };
    this.updateStatusBar();
    this.updateErrorList();
    this.hideStatusBar();
  }
  showStatusBar() {
    if (this.statusBar) {
      this.statusBar.style.display = "block";
    }
  }
  hideStatusBar() {
    if (this.statusBar) {
      this.statusBar.style.display = "none";
      this.isExpanded = false;
      const errorDetails = document.getElementById("error-details");
      const toggleText = document.getElementById("toggle-text");
      const toggleIcon = document.getElementById("toggle-icon");
      if (errorDetails) errorDetails.style.display = "none";
      if (toggleText) toggleText.textContent = "Show";
      if (toggleIcon) toggleIcon.textContent = "\u2191";
    }
  }
  flashNewError() {
    if (this.statusBar) {
      this.statusBar.style.borderTopColor = "#ef4444";
      this.statusBar.style.borderTopWidth = "2px";
      setTimeout(() => {
        if (this.statusBar) {
          this.statusBar.style.borderTopColor = "#374151";
          this.statusBar.style.borderTopWidth = "1px";
        }
      }, 1e3);
    }
  }
  sanitizeMessage(message) {
    if (!message) return "Unknown error";
    const cleanMessage = message.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#39;").replace(/\n/g, " ").trim();
    return cleanMessage.length > 100 ? `${cleanMessage.substring(0, 100)}...` : cleanMessage;
  }
  truncateText(text, maxLength) {
    if (!text) return "";
    if (text.length <= maxLength) return text;
    return `${text.substring(0, maxLength)}... [truncated]`;
  }
  extractFilename(filepath) {
    if (!filepath) return "";
    return filepath.split("/").pop() || filepath;
  }
  cleanupDebounceMap() {
    const cutoffTime = Date.now() - this.debounceTime * 10;
    for (const [key, timestamp] of this.recentErrorsDebounce.entries()) {
      if (timestamp < cutoffTime) {
        this.recentErrorsDebounce.delete(key);
      }
    }
  }
  formatLastUserAction() {
    if (!this.lastUserAction) return "";
    const timeDiff = Date.now() - this.lastUserAction.timestamp;
    if (timeDiff > 5e3) return "";
    const secondsAgo = (timeDiff / 1e3).toFixed(1);
    let actionDesc = `Last User Action: ${this.lastUserAction.type} ${this.lastUserAction.element}`;
    if (this.lastUserAction.text) {
      actionDesc += ` "${this.lastUserAction.text}"`;
    }
    if (this.lastUserAction.stimulusAction) {
      actionDesc += ` [data-action="${this.lastUserAction.stimulusAction}"]`;
    }
    if (this.lastUserAction.stimulusController) {
      actionDesc += ` [controller="${this.lastUserAction.stimulusController}"]`;
    }
    actionDesc += ` (${secondsAgo}s ago)`;
    return `${actionDesc}
`;
  }
  // Public API methods
  getErrors() {
    return this.errors;
  }
  reportError(message, context = {}) {
    this.handleError({
      message,
      type: "manual",
      timestamp: (/* @__PURE__ */ new Date()).toISOString(),
      ...context
    });
  }
  // ActionCable specific error capturing
  captureActionCableError(errorData) {
    this.errorCounts.actioncable++;
    const errorInfo = {
      type: "actioncable",
      message: errorData.message || "ActionCable error occurred",
      timestamp: (/* @__PURE__ */ new Date()).toISOString(),
      channel: errorData.channel || "unknown",
      action: errorData.action || "unknown",
      filename: `channel: ${errorData.channel}`,
      lineno: 0,
      details: errorData
    };
    this.handleError(errorInfo);
  }
  // Source Map related methods
  async getSourceMapConsumer(fileUrl) {
    if (this.sourceMapCache.has(fileUrl)) {
      return this.sourceMapCache.get(fileUrl);
    }
    if (this.sourceMapPending.has(fileUrl)) {
      return this.sourceMapPending.get(fileUrl);
    }
    const promise = this.loadSourceMap(fileUrl);
    this.sourceMapPending.set(fileUrl, promise);
    const consumer = await promise;
    this.sourceMapPending.delete(fileUrl);
    if (consumer) {
      this.sourceMapCache.set(fileUrl, consumer);
    }
    return consumer;
  }
  async loadSourceMap(fileUrl) {
    try {
      const response = await fetch(fileUrl);
      const sourceCode = await response.text();
      const sourceMapMatch = sourceCode.match(/\/\/# sourceMappingURL=data:application\/json;base64,([^\s]+)/);
      if (!sourceMapMatch) {
        return null;
      }
      const base64SourceMap = sourceMapMatch[1];
      const sourceMapJson = atob(base64SourceMap);
      const sourceMap = JSON.parse(sourceMapJson);
      return await new import_source_map_js.SourceMapConsumer(sourceMap);
    } catch (error) {
      this.originalConsoleError("Failed to load source map for", fileUrl, error);
      return null;
    }
  }
  normalizeSourcePath(sourcePath) {
    if (!sourcePath) return sourcePath;
    let normalized = sourcePath.replace(/^(?:\.\.\/)+/, "").replace(/^\.\//, "");
    if (normalized.startsWith("javascript/")) {
      normalized = `app/${normalized}`;
    }
    return normalized;
  }
  async mapStackTrace(stack) {
    if (!stack) return stack;
    const lines = stack.split("\n");
    const mappedLines = await Promise.all(lines.map(async (line) => {
      const match = line.match(/^\s*at\s+(?:(.+?)\s+\()?(.+?):(\d+):(\d+)\)?$/);
      if (!match) return line;
      const [, functionName, fileUrl, lineStr, columnStr] = match;
      const line_num = parseInt(lineStr, 10);
      const column = parseInt(columnStr, 10);
      if (!fileUrl || !fileUrl.startsWith("http://") && !fileUrl.startsWith("https://")) {
        return line;
      }
      const consumer = await this.getSourceMapConsumer(fileUrl);
      if (!consumer) return line;
      const originalPosition = consumer.originalPositionFor({
        line: line_num,
        column
      });
      if (originalPosition.source) {
        const normalizedSource = this.normalizeSourcePath(originalPosition.source);
        const prefix = functionName ? `at ${functionName} (` : "at ";
        const suffix = functionName ? ")" : "";
        return `${prefix}${normalizedSource}:${originalPosition.line}:${originalPosition.column}${suffix}`;
      }
      return line;
    }));
    return mappedLines.join("\n");
  }
  async enrichErrorWithSourceMap(errorInfo) {
    let enriched = { ...errorInfo };
    if (errorInfo.filename && errorInfo.lineno && errorInfo.colno) {
      try {
        const consumer = await this.getSourceMapConsumer(errorInfo.filename);
        if (consumer) {
          const originalPosition = consumer.originalPositionFor({
            line: errorInfo.lineno,
            column: errorInfo.colno
          });
          if (originalPosition.source) {
            enriched = {
              ...enriched,
              filename: this.normalizeSourcePath(originalPosition.source),
              lineno: originalPosition.line || errorInfo.lineno,
              colno: originalPosition.column !== null ? originalPosition.column : errorInfo.colno
            };
          }
        }
      } catch (error) {
        this.originalConsoleError("Failed to map error position", error);
      }
    }
    if (errorInfo.error?.stack) {
      try {
        const mappedStack = await this.mapStackTrace(errorInfo.error.stack);
        enriched = {
          ...enriched,
          error: {
            ...errorInfo.error,
            stack: mappedStack
          }
        };
      } catch (error) {
        this.originalConsoleError("Failed to map stack trace", error);
      }
    }
    return enriched;
  }
};
if (!window.errorHandler) {
  window.errorHandler = new ErrorHandler();
}
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsiLi4vLi4vLi4vbm9kZV9tb2R1bGVzL3NvdXJjZS1tYXAtanMvbGliL2Jhc2U2NC5qcyIsICIuLi8uLi8uLi9ub2RlX21vZHVsZXMvc291cmNlLW1hcC1qcy9saWIvYmFzZTY0LXZscS5qcyIsICIuLi8uLi8uLi9ub2RlX21vZHVsZXMvc291cmNlLW1hcC1qcy9saWIvdXRpbC5qcyIsICIuLi8uLi8uLi9ub2RlX21vZHVsZXMvc291cmNlLW1hcC1qcy9saWIvYXJyYXktc2V0LmpzIiwgIi4uLy4uLy4uL25vZGVfbW9kdWxlcy9zb3VyY2UtbWFwLWpzL2xpYi9tYXBwaW5nLWxpc3QuanMiLCAiLi4vLi4vLi4vbm9kZV9tb2R1bGVzL3NvdXJjZS1tYXAtanMvbGliL3NvdXJjZS1tYXAtZ2VuZXJhdG9yLmpzIiwgIi4uLy4uLy4uL25vZGVfbW9kdWxlcy9zb3VyY2UtbWFwLWpzL2xpYi9iaW5hcnktc2VhcmNoLmpzIiwgIi4uLy4uLy4uL25vZGVfbW9kdWxlcy9zb3VyY2UtbWFwLWpzL2xpYi9xdWljay1zb3J0LmpzIiwgIi4uLy4uLy4uL25vZGVfbW9kdWxlcy9zb3VyY2UtbWFwLWpzL2xpYi9zb3VyY2UtbWFwLWNvbnN1bWVyLmpzIiwgIi4uLy4uLy4uL25vZGVfbW9kdWxlcy9zb3VyY2UtbWFwLWpzL2xpYi9zb3VyY2Utbm9kZS5qcyIsICIuLi8uLi8uLi9ub2RlX21vZHVsZXMvc291cmNlLW1hcC1qcy9zb3VyY2UtbWFwLmpzIiwgIi4uLy4uL2phdmFzY3JpcHQvZXJyb3JfaGFuZGxlci50cyJdLAogICJzb3VyY2VzQ29udGVudCI6IFsiLyogLSotIE1vZGU6IGpzOyBqcy1pbmRlbnQtbGV2ZWw6IDI7IC0qLSAqL1xuLypcbiAqIENvcHlyaWdodCAyMDExIE1vemlsbGEgRm91bmRhdGlvbiBhbmQgY29udHJpYnV0b3JzXG4gKiBMaWNlbnNlZCB1bmRlciB0aGUgTmV3IEJTRCBsaWNlbnNlLiBTZWUgTElDRU5TRSBvcjpcbiAqIGh0dHA6Ly9vcGVuc291cmNlLm9yZy9saWNlbnNlcy9CU0QtMy1DbGF1c2VcbiAqL1xuXG52YXIgaW50VG9DaGFyTWFwID0gJ0FCQ0RFRkdISUpLTE1OT1BRUlNUVVZXWFlaYWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXowMTIzNDU2Nzg5Ky8nLnNwbGl0KCcnKTtcblxuLyoqXG4gKiBFbmNvZGUgYW4gaW50ZWdlciBpbiB0aGUgcmFuZ2Ugb2YgMCB0byA2MyB0byBhIHNpbmdsZSBiYXNlIDY0IGRpZ2l0LlxuICovXG5leHBvcnRzLmVuY29kZSA9IGZ1bmN0aW9uIChudW1iZXIpIHtcbiAgaWYgKDAgPD0gbnVtYmVyICYmIG51bWJlciA8IGludFRvQ2hhck1hcC5sZW5ndGgpIHtcbiAgICByZXR1cm4gaW50VG9DaGFyTWFwW251bWJlcl07XG4gIH1cbiAgdGhyb3cgbmV3IFR5cGVFcnJvcihcIk11c3QgYmUgYmV0d2VlbiAwIGFuZCA2MzogXCIgKyBudW1iZXIpO1xufTtcblxuLyoqXG4gKiBEZWNvZGUgYSBzaW5nbGUgYmFzZSA2NCBjaGFyYWN0ZXIgY29kZSBkaWdpdCB0byBhbiBpbnRlZ2VyLiBSZXR1cm5zIC0xIG9uXG4gKiBmYWlsdXJlLlxuICovXG5leHBvcnRzLmRlY29kZSA9IGZ1bmN0aW9uIChjaGFyQ29kZSkge1xuICB2YXIgYmlnQSA9IDY1OyAgICAgLy8gJ0EnXG4gIHZhciBiaWdaID0gOTA7ICAgICAvLyAnWidcblxuICB2YXIgbGl0dGxlQSA9IDk3OyAgLy8gJ2EnXG4gIHZhciBsaXR0bGVaID0gMTIyOyAvLyAneidcblxuICB2YXIgemVybyA9IDQ4OyAgICAgLy8gJzAnXG4gIHZhciBuaW5lID0gNTc7ICAgICAvLyAnOSdcblxuICB2YXIgcGx1cyA9IDQzOyAgICAgLy8gJysnXG4gIHZhciBzbGFzaCA9IDQ3OyAgICAvLyAnLydcblxuICB2YXIgbGl0dGxlT2Zmc2V0ID0gMjY7XG4gIHZhciBudW1iZXJPZmZzZXQgPSA1MjtcblxuICAvLyAwIC0gMjU6IEFCQ0RFRkdISUpLTE1OT1BRUlNUVVZXWFlaXG4gIGlmIChiaWdBIDw9IGNoYXJDb2RlICYmIGNoYXJDb2RlIDw9IGJpZ1opIHtcbiAgICByZXR1cm4gKGNoYXJDb2RlIC0gYmlnQSk7XG4gIH1cblxuICAvLyAyNiAtIDUxOiBhYmNkZWZnaGlqa2xtbm9wcXJzdHV2d3h5elxuICBpZiAobGl0dGxlQSA8PSBjaGFyQ29kZSAmJiBjaGFyQ29kZSA8PSBsaXR0bGVaKSB7XG4gICAgcmV0dXJuIChjaGFyQ29kZSAtIGxpdHRsZUEgKyBsaXR0bGVPZmZzZXQpO1xuICB9XG5cbiAgLy8gNTIgLSA2MTogMDEyMzQ1Njc4OVxuICBpZiAoemVybyA8PSBjaGFyQ29kZSAmJiBjaGFyQ29kZSA8PSBuaW5lKSB7XG4gICAgcmV0dXJuIChjaGFyQ29kZSAtIHplcm8gKyBudW1iZXJPZmZzZXQpO1xuICB9XG5cbiAgLy8gNjI6ICtcbiAgaWYgKGNoYXJDb2RlID09IHBsdXMpIHtcbiAgICByZXR1cm4gNjI7XG4gIH1cblxuICAvLyA2MzogL1xuICBpZiAoY2hhckNvZGUgPT0gc2xhc2gpIHtcbiAgICByZXR1cm4gNjM7XG4gIH1cblxuICAvLyBJbnZhbGlkIGJhc2U2NCBkaWdpdC5cbiAgcmV0dXJuIC0xO1xufTtcbiIsICIvKiAtKi0gTW9kZToganM7IGpzLWluZGVudC1sZXZlbDogMjsgLSotICovXG4vKlxuICogQ29weXJpZ2h0IDIwMTEgTW96aWxsYSBGb3VuZGF0aW9uIGFuZCBjb250cmlidXRvcnNcbiAqIExpY2Vuc2VkIHVuZGVyIHRoZSBOZXcgQlNEIGxpY2Vuc2UuIFNlZSBMSUNFTlNFIG9yOlxuICogaHR0cDovL29wZW5zb3VyY2Uub3JnL2xpY2Vuc2VzL0JTRC0zLUNsYXVzZVxuICpcbiAqIEJhc2VkIG9uIHRoZSBCYXNlIDY0IFZMUSBpbXBsZW1lbnRhdGlvbiBpbiBDbG9zdXJlIENvbXBpbGVyOlxuICogaHR0cHM6Ly9jb2RlLmdvb2dsZS5jb20vcC9jbG9zdXJlLWNvbXBpbGVyL3NvdXJjZS9icm93c2UvdHJ1bmsvc3JjL2NvbS9nb29nbGUvZGVidWdnaW5nL3NvdXJjZW1hcC9CYXNlNjRWTFEuamF2YVxuICpcbiAqIENvcHlyaWdodCAyMDExIFRoZSBDbG9zdXJlIENvbXBpbGVyIEF1dGhvcnMuIEFsbCByaWdodHMgcmVzZXJ2ZWQuXG4gKiBSZWRpc3RyaWJ1dGlvbiBhbmQgdXNlIGluIHNvdXJjZSBhbmQgYmluYXJ5IGZvcm1zLCB3aXRoIG9yIHdpdGhvdXRcbiAqIG1vZGlmaWNhdGlvbiwgYXJlIHBlcm1pdHRlZCBwcm92aWRlZCB0aGF0IHRoZSBmb2xsb3dpbmcgY29uZGl0aW9ucyBhcmVcbiAqIG1ldDpcbiAqXG4gKiAgKiBSZWRpc3RyaWJ1dGlvbnMgb2Ygc291cmNlIGNvZGUgbXVzdCByZXRhaW4gdGhlIGFib3ZlIGNvcHlyaWdodFxuICogICAgbm90aWNlLCB0aGlzIGxpc3Qgb2YgY29uZGl0aW9ucyBhbmQgdGhlIGZvbGxvd2luZyBkaXNjbGFpbWVyLlxuICogICogUmVkaXN0cmlidXRpb25zIGluIGJpbmFyeSBmb3JtIG11c3QgcmVwcm9kdWNlIHRoZSBhYm92ZVxuICogICAgY29weXJpZ2h0IG5vdGljZSwgdGhpcyBsaXN0IG9mIGNvbmRpdGlvbnMgYW5kIHRoZSBmb2xsb3dpbmdcbiAqICAgIGRpc2NsYWltZXIgaW4gdGhlIGRvY3VtZW50YXRpb24gYW5kL29yIG90aGVyIG1hdGVyaWFscyBwcm92aWRlZFxuICogICAgd2l0aCB0aGUgZGlzdHJpYnV0aW9uLlxuICogICogTmVpdGhlciB0aGUgbmFtZSBvZiBHb29nbGUgSW5jLiBub3IgdGhlIG5hbWVzIG9mIGl0c1xuICogICAgY29udHJpYnV0b3JzIG1heSBiZSB1c2VkIHRvIGVuZG9yc2Ugb3IgcHJvbW90ZSBwcm9kdWN0cyBkZXJpdmVkXG4gKiAgICBmcm9tIHRoaXMgc29mdHdhcmUgd2l0aG91dCBzcGVjaWZpYyBwcmlvciB3cml0dGVuIHBlcm1pc3Npb24uXG4gKlxuICogVEhJUyBTT0ZUV0FSRSBJUyBQUk9WSURFRCBCWSBUSEUgQ09QWVJJR0hUIEhPTERFUlMgQU5EIENPTlRSSUJVVE9SU1xuICogXCJBUyBJU1wiIEFORCBBTlkgRVhQUkVTUyBPUiBJTVBMSUVEIFdBUlJBTlRJRVMsIElOQ0xVRElORywgQlVUIE5PVFxuICogTElNSVRFRCBUTywgVEhFIElNUExJRUQgV0FSUkFOVElFUyBPRiBNRVJDSEFOVEFCSUxJVFkgQU5EIEZJVE5FU1MgRk9SXG4gKiBBIFBBUlRJQ1VMQVIgUFVSUE9TRSBBUkUgRElTQ0xBSU1FRC4gSU4gTk8gRVZFTlQgU0hBTEwgVEhFIENPUFlSSUdIVFxuICogT1dORVIgT1IgQ09OVFJJQlVUT1JTIEJFIExJQUJMRSBGT1IgQU5ZIERJUkVDVCwgSU5ESVJFQ1QsIElOQ0lERU5UQUwsXG4gKiBTUEVDSUFMLCBFWEVNUExBUlksIE9SIENPTlNFUVVFTlRJQUwgREFNQUdFUyAoSU5DTFVESU5HLCBCVVQgTk9UXG4gKiBMSU1JVEVEIFRPLCBQUk9DVVJFTUVOVCBPRiBTVUJTVElUVVRFIEdPT0RTIE9SIFNFUlZJQ0VTOyBMT1NTIE9GIFVTRSxcbiAqIERBVEEsIE9SIFBST0ZJVFM7IE9SIEJVU0lORVNTIElOVEVSUlVQVElPTikgSE9XRVZFUiBDQVVTRUQgQU5EIE9OIEFOWVxuICogVEhFT1JZIE9GIExJQUJJTElUWSwgV0hFVEhFUiBJTiBDT05UUkFDVCwgU1RSSUNUIExJQUJJTElUWSwgT1IgVE9SVFxuICogKElOQ0xVRElORyBORUdMSUdFTkNFIE9SIE9USEVSV0lTRSkgQVJJU0lORyBJTiBBTlkgV0FZIE9VVCBPRiBUSEUgVVNFXG4gKiBPRiBUSElTIFNPRlRXQVJFLCBFVkVOIElGIEFEVklTRUQgT0YgVEhFIFBPU1NJQklMSVRZIE9GIFNVQ0ggREFNQUdFLlxuICovXG5cbnZhciBiYXNlNjQgPSByZXF1aXJlKCcuL2Jhc2U2NCcpO1xuXG4vLyBBIHNpbmdsZSBiYXNlIDY0IGRpZ2l0IGNhbiBjb250YWluIDYgYml0cyBvZiBkYXRhLiBGb3IgdGhlIGJhc2UgNjQgdmFyaWFibGVcbi8vIGxlbmd0aCBxdWFudGl0aWVzIHdlIHVzZSBpbiB0aGUgc291cmNlIG1hcCBzcGVjLCB0aGUgZmlyc3QgYml0IGlzIHRoZSBzaWduLFxuLy8gdGhlIG5leHQgZm91ciBiaXRzIGFyZSB0aGUgYWN0dWFsIHZhbHVlLCBhbmQgdGhlIDZ0aCBiaXQgaXMgdGhlXG4vLyBjb250aW51YXRpb24gYml0LiBUaGUgY29udGludWF0aW9uIGJpdCB0ZWxscyB1cyB3aGV0aGVyIHRoZXJlIGFyZSBtb3JlXG4vLyBkaWdpdHMgaW4gdGhpcyB2YWx1ZSBmb2xsb3dpbmcgdGhpcyBkaWdpdC5cbi8vXG4vLyAgIENvbnRpbnVhdGlvblxuLy8gICB8ICAgIFNpZ25cbi8vICAgfCAgICB8XG4vLyAgIFYgICAgVlxuLy8gICAxMDEwMTFcblxudmFyIFZMUV9CQVNFX1NISUZUID0gNTtcblxuLy8gYmluYXJ5OiAxMDAwMDBcbnZhciBWTFFfQkFTRSA9IDEgPDwgVkxRX0JBU0VfU0hJRlQ7XG5cbi8vIGJpbmFyeTogMDExMTExXG52YXIgVkxRX0JBU0VfTUFTSyA9IFZMUV9CQVNFIC0gMTtcblxuLy8gYmluYXJ5OiAxMDAwMDBcbnZhciBWTFFfQ09OVElOVUFUSU9OX0JJVCA9IFZMUV9CQVNFO1xuXG4vKipcbiAqIENvbnZlcnRzIGZyb20gYSB0d28tY29tcGxlbWVudCB2YWx1ZSB0byBhIHZhbHVlIHdoZXJlIHRoZSBzaWduIGJpdCBpc1xuICogcGxhY2VkIGluIHRoZSBsZWFzdCBzaWduaWZpY2FudCBiaXQuICBGb3IgZXhhbXBsZSwgYXMgZGVjaW1hbHM6XG4gKiAgIDEgYmVjb21lcyAyICgxMCBiaW5hcnkpLCAtMSBiZWNvbWVzIDMgKDExIGJpbmFyeSlcbiAqICAgMiBiZWNvbWVzIDQgKDEwMCBiaW5hcnkpLCAtMiBiZWNvbWVzIDUgKDEwMSBiaW5hcnkpXG4gKi9cbmZ1bmN0aW9uIHRvVkxRU2lnbmVkKGFWYWx1ZSkge1xuICByZXR1cm4gYVZhbHVlIDwgMFxuICAgID8gKCgtYVZhbHVlKSA8PCAxKSArIDFcbiAgICA6IChhVmFsdWUgPDwgMSkgKyAwO1xufVxuXG4vKipcbiAqIENvbnZlcnRzIHRvIGEgdHdvLWNvbXBsZW1lbnQgdmFsdWUgZnJvbSBhIHZhbHVlIHdoZXJlIHRoZSBzaWduIGJpdCBpc1xuICogcGxhY2VkIGluIHRoZSBsZWFzdCBzaWduaWZpY2FudCBiaXQuICBGb3IgZXhhbXBsZSwgYXMgZGVjaW1hbHM6XG4gKiAgIDIgKDEwIGJpbmFyeSkgYmVjb21lcyAxLCAzICgxMSBiaW5hcnkpIGJlY29tZXMgLTFcbiAqICAgNCAoMTAwIGJpbmFyeSkgYmVjb21lcyAyLCA1ICgxMDEgYmluYXJ5KSBiZWNvbWVzIC0yXG4gKi9cbmZ1bmN0aW9uIGZyb21WTFFTaWduZWQoYVZhbHVlKSB7XG4gIHZhciBpc05lZ2F0aXZlID0gKGFWYWx1ZSAmIDEpID09PSAxO1xuICB2YXIgc2hpZnRlZCA9IGFWYWx1ZSA+PiAxO1xuICByZXR1cm4gaXNOZWdhdGl2ZVxuICAgID8gLXNoaWZ0ZWRcbiAgICA6IHNoaWZ0ZWQ7XG59XG5cbi8qKlxuICogUmV0dXJucyB0aGUgYmFzZSA2NCBWTFEgZW5jb2RlZCB2YWx1ZS5cbiAqL1xuZXhwb3J0cy5lbmNvZGUgPSBmdW5jdGlvbiBiYXNlNjRWTFFfZW5jb2RlKGFWYWx1ZSkge1xuICB2YXIgZW5jb2RlZCA9IFwiXCI7XG4gIHZhciBkaWdpdDtcblxuICB2YXIgdmxxID0gdG9WTFFTaWduZWQoYVZhbHVlKTtcblxuICBkbyB7XG4gICAgZGlnaXQgPSB2bHEgJiBWTFFfQkFTRV9NQVNLO1xuICAgIHZscSA+Pj49IFZMUV9CQVNFX1NISUZUO1xuICAgIGlmICh2bHEgPiAwKSB7XG4gICAgICAvLyBUaGVyZSBhcmUgc3RpbGwgbW9yZSBkaWdpdHMgaW4gdGhpcyB2YWx1ZSwgc28gd2UgbXVzdCBtYWtlIHN1cmUgdGhlXG4gICAgICAvLyBjb250aW51YXRpb24gYml0IGlzIG1hcmtlZC5cbiAgICAgIGRpZ2l0IHw9IFZMUV9DT05USU5VQVRJT05fQklUO1xuICAgIH1cbiAgICBlbmNvZGVkICs9IGJhc2U2NC5lbmNvZGUoZGlnaXQpO1xuICB9IHdoaWxlICh2bHEgPiAwKTtcblxuICByZXR1cm4gZW5jb2RlZDtcbn07XG5cbi8qKlxuICogRGVjb2RlcyB0aGUgbmV4dCBiYXNlIDY0IFZMUSB2YWx1ZSBmcm9tIHRoZSBnaXZlbiBzdHJpbmcgYW5kIHJldHVybnMgdGhlXG4gKiB2YWx1ZSBhbmQgdGhlIHJlc3Qgb2YgdGhlIHN0cmluZyB2aWEgdGhlIG91dCBwYXJhbWV0ZXIuXG4gKi9cbmV4cG9ydHMuZGVjb2RlID0gZnVuY3Rpb24gYmFzZTY0VkxRX2RlY29kZShhU3RyLCBhSW5kZXgsIGFPdXRQYXJhbSkge1xuICB2YXIgc3RyTGVuID0gYVN0ci5sZW5ndGg7XG4gIHZhciByZXN1bHQgPSAwO1xuICB2YXIgc2hpZnQgPSAwO1xuICB2YXIgY29udGludWF0aW9uLCBkaWdpdDtcblxuICBkbyB7XG4gICAgaWYgKGFJbmRleCA+PSBzdHJMZW4pIHtcbiAgICAgIHRocm93IG5ldyBFcnJvcihcIkV4cGVjdGVkIG1vcmUgZGlnaXRzIGluIGJhc2UgNjQgVkxRIHZhbHVlLlwiKTtcbiAgICB9XG5cbiAgICBkaWdpdCA9IGJhc2U2NC5kZWNvZGUoYVN0ci5jaGFyQ29kZUF0KGFJbmRleCsrKSk7XG4gICAgaWYgKGRpZ2l0ID09PSAtMSkge1xuICAgICAgdGhyb3cgbmV3IEVycm9yKFwiSW52YWxpZCBiYXNlNjQgZGlnaXQ6IFwiICsgYVN0ci5jaGFyQXQoYUluZGV4IC0gMSkpO1xuICAgIH1cblxuICAgIGNvbnRpbnVhdGlvbiA9ICEhKGRpZ2l0ICYgVkxRX0NPTlRJTlVBVElPTl9CSVQpO1xuICAgIGRpZ2l0ICY9IFZMUV9CQVNFX01BU0s7XG4gICAgcmVzdWx0ID0gcmVzdWx0ICsgKGRpZ2l0IDw8IHNoaWZ0KTtcbiAgICBzaGlmdCArPSBWTFFfQkFTRV9TSElGVDtcbiAgfSB3aGlsZSAoY29udGludWF0aW9uKTtcblxuICBhT3V0UGFyYW0udmFsdWUgPSBmcm9tVkxRU2lnbmVkKHJlc3VsdCk7XG4gIGFPdXRQYXJhbS5yZXN0ID0gYUluZGV4O1xufTtcbiIsICIvKiAtKi0gTW9kZToganM7IGpzLWluZGVudC1sZXZlbDogMjsgLSotICovXG4vKlxuICogQ29weXJpZ2h0IDIwMTEgTW96aWxsYSBGb3VuZGF0aW9uIGFuZCBjb250cmlidXRvcnNcbiAqIExpY2Vuc2VkIHVuZGVyIHRoZSBOZXcgQlNEIGxpY2Vuc2UuIFNlZSBMSUNFTlNFIG9yOlxuICogaHR0cDovL29wZW5zb3VyY2Uub3JnL2xpY2Vuc2VzL0JTRC0zLUNsYXVzZVxuICovXG5cbi8qKlxuICogVGhpcyBpcyBhIGhlbHBlciBmdW5jdGlvbiBmb3IgZ2V0dGluZyB2YWx1ZXMgZnJvbSBwYXJhbWV0ZXIvb3B0aW9uc1xuICogb2JqZWN0cy5cbiAqXG4gKiBAcGFyYW0gYXJncyBUaGUgb2JqZWN0IHdlIGFyZSBleHRyYWN0aW5nIHZhbHVlcyBmcm9tXG4gKiBAcGFyYW0gbmFtZSBUaGUgbmFtZSBvZiB0aGUgcHJvcGVydHkgd2UgYXJlIGdldHRpbmcuXG4gKiBAcGFyYW0gZGVmYXVsdFZhbHVlIEFuIG9wdGlvbmFsIHZhbHVlIHRvIHJldHVybiBpZiB0aGUgcHJvcGVydHkgaXMgbWlzc2luZ1xuICogZnJvbSB0aGUgb2JqZWN0LiBJZiB0aGlzIGlzIG5vdCBzcGVjaWZpZWQgYW5kIHRoZSBwcm9wZXJ0eSBpcyBtaXNzaW5nLCBhblxuICogZXJyb3Igd2lsbCBiZSB0aHJvd24uXG4gKi9cbmZ1bmN0aW9uIGdldEFyZyhhQXJncywgYU5hbWUsIGFEZWZhdWx0VmFsdWUpIHtcbiAgaWYgKGFOYW1lIGluIGFBcmdzKSB7XG4gICAgcmV0dXJuIGFBcmdzW2FOYW1lXTtcbiAgfSBlbHNlIGlmIChhcmd1bWVudHMubGVuZ3RoID09PSAzKSB7XG4gICAgcmV0dXJuIGFEZWZhdWx0VmFsdWU7XG4gIH0gZWxzZSB7XG4gICAgdGhyb3cgbmV3IEVycm9yKCdcIicgKyBhTmFtZSArICdcIiBpcyBhIHJlcXVpcmVkIGFyZ3VtZW50LicpO1xuICB9XG59XG5leHBvcnRzLmdldEFyZyA9IGdldEFyZztcblxudmFyIHVybFJlZ2V4cCA9IC9eKD86KFtcXHcrXFwtLl0rKTopP1xcL1xcLyg/OihcXHcrOlxcdyspQCk/KFtcXHcuLV0qKSg/OjooXFxkKykpPyguKikkLztcbnZhciBkYXRhVXJsUmVnZXhwID0gL15kYXRhOi4rXFwsLiskLztcblxuZnVuY3Rpb24gdXJsUGFyc2UoYVVybCkge1xuICB2YXIgbWF0Y2ggPSBhVXJsLm1hdGNoKHVybFJlZ2V4cCk7XG4gIGlmICghbWF0Y2gpIHtcbiAgICByZXR1cm4gbnVsbDtcbiAgfVxuICByZXR1cm4ge1xuICAgIHNjaGVtZTogbWF0Y2hbMV0sXG4gICAgYXV0aDogbWF0Y2hbMl0sXG4gICAgaG9zdDogbWF0Y2hbM10sXG4gICAgcG9ydDogbWF0Y2hbNF0sXG4gICAgcGF0aDogbWF0Y2hbNV1cbiAgfTtcbn1cbmV4cG9ydHMudXJsUGFyc2UgPSB1cmxQYXJzZTtcblxuZnVuY3Rpb24gdXJsR2VuZXJhdGUoYVBhcnNlZFVybCkge1xuICB2YXIgdXJsID0gJyc7XG4gIGlmIChhUGFyc2VkVXJsLnNjaGVtZSkge1xuICAgIHVybCArPSBhUGFyc2VkVXJsLnNjaGVtZSArICc6JztcbiAgfVxuICB1cmwgKz0gJy8vJztcbiAgaWYgKGFQYXJzZWRVcmwuYXV0aCkge1xuICAgIHVybCArPSBhUGFyc2VkVXJsLmF1dGggKyAnQCc7XG4gIH1cbiAgaWYgKGFQYXJzZWRVcmwuaG9zdCkge1xuICAgIHVybCArPSBhUGFyc2VkVXJsLmhvc3Q7XG4gIH1cbiAgaWYgKGFQYXJzZWRVcmwucG9ydCkge1xuICAgIHVybCArPSBcIjpcIiArIGFQYXJzZWRVcmwucG9ydFxuICB9XG4gIGlmIChhUGFyc2VkVXJsLnBhdGgpIHtcbiAgICB1cmwgKz0gYVBhcnNlZFVybC5wYXRoO1xuICB9XG4gIHJldHVybiB1cmw7XG59XG5leHBvcnRzLnVybEdlbmVyYXRlID0gdXJsR2VuZXJhdGU7XG5cbnZhciBNQVhfQ0FDSEVEX0lOUFVUUyA9IDMyO1xuXG4vKipcbiAqIFRha2VzIHNvbWUgZnVuY3Rpb24gYGYoaW5wdXQpIC0+IHJlc3VsdGAgYW5kIHJldHVybnMgYSBtZW1vaXplZCB2ZXJzaW9uIG9mXG4gKiBgZmAuXG4gKlxuICogV2Uga2VlcCBhdCBtb3N0IGBNQVhfQ0FDSEVEX0lOUFVUU2AgbWVtb2l6ZWQgcmVzdWx0cyBvZiBgZmAgYWxpdmUuIFRoZVxuICogbWVtb2l6YXRpb24gaXMgYSBkdW1iLXNpbXBsZSwgbGluZWFyIGxlYXN0LXJlY2VudGx5LXVzZWQgY2FjaGUuXG4gKi9cbmZ1bmN0aW9uIGxydU1lbW9pemUoZikge1xuICB2YXIgY2FjaGUgPSBbXTtcblxuICByZXR1cm4gZnVuY3Rpb24oaW5wdXQpIHtcbiAgICBmb3IgKHZhciBpID0gMDsgaSA8IGNhY2hlLmxlbmd0aDsgaSsrKSB7XG4gICAgICBpZiAoY2FjaGVbaV0uaW5wdXQgPT09IGlucHV0KSB7XG4gICAgICAgIHZhciB0ZW1wID0gY2FjaGVbMF07XG4gICAgICAgIGNhY2hlWzBdID0gY2FjaGVbaV07XG4gICAgICAgIGNhY2hlW2ldID0gdGVtcDtcbiAgICAgICAgcmV0dXJuIGNhY2hlWzBdLnJlc3VsdDtcbiAgICAgIH1cbiAgICB9XG5cbiAgICB2YXIgcmVzdWx0ID0gZihpbnB1dCk7XG5cbiAgICBjYWNoZS51bnNoaWZ0KHtcbiAgICAgIGlucHV0LFxuICAgICAgcmVzdWx0LFxuICAgIH0pO1xuXG4gICAgaWYgKGNhY2hlLmxlbmd0aCA+IE1BWF9DQUNIRURfSU5QVVRTKSB7XG4gICAgICBjYWNoZS5wb3AoKTtcbiAgICB9XG5cbiAgICByZXR1cm4gcmVzdWx0O1xuICB9O1xufVxuXG4vKipcbiAqIE5vcm1hbGl6ZXMgYSBwYXRoLCBvciB0aGUgcGF0aCBwb3J0aW9uIG9mIGEgVVJMOlxuICpcbiAqIC0gUmVwbGFjZXMgY29uc2VjdXRpdmUgc2xhc2hlcyB3aXRoIG9uZSBzbGFzaC5cbiAqIC0gUmVtb3ZlcyB1bm5lY2Vzc2FyeSAnLicgcGFydHMuXG4gKiAtIFJlbW92ZXMgdW5uZWNlc3NhcnkgJzxkaXI+Ly4uJyBwYXJ0cy5cbiAqXG4gKiBCYXNlZCBvbiBjb2RlIGluIHRoZSBOb2RlLmpzICdwYXRoJyBjb3JlIG1vZHVsZS5cbiAqXG4gKiBAcGFyYW0gYVBhdGggVGhlIHBhdGggb3IgdXJsIHRvIG5vcm1hbGl6ZS5cbiAqL1xudmFyIG5vcm1hbGl6ZSA9IGxydU1lbW9pemUoZnVuY3Rpb24gbm9ybWFsaXplKGFQYXRoKSB7XG4gIHZhciBwYXRoID0gYVBhdGg7XG4gIHZhciB1cmwgPSB1cmxQYXJzZShhUGF0aCk7XG4gIGlmICh1cmwpIHtcbiAgICBpZiAoIXVybC5wYXRoKSB7XG4gICAgICByZXR1cm4gYVBhdGg7XG4gICAgfVxuICAgIHBhdGggPSB1cmwucGF0aDtcbiAgfVxuICB2YXIgaXNBYnNvbHV0ZSA9IGV4cG9ydHMuaXNBYnNvbHV0ZShwYXRoKTtcbiAgLy8gU3BsaXQgdGhlIHBhdGggaW50byBwYXJ0cyBiZXR3ZWVuIGAvYCBjaGFyYWN0ZXJzLiBUaGlzIGlzIG11Y2ggZmFzdGVyIHRoYW5cbiAgLy8gdXNpbmcgYC5zcGxpdCgvXFwvKy9nKWAuXG4gIHZhciBwYXJ0cyA9IFtdO1xuICB2YXIgc3RhcnQgPSAwO1xuICB2YXIgaSA9IDA7XG4gIHdoaWxlICh0cnVlKSB7XG4gICAgc3RhcnQgPSBpO1xuICAgIGkgPSBwYXRoLmluZGV4T2YoXCIvXCIsIHN0YXJ0KTtcbiAgICBpZiAoaSA9PT0gLTEpIHtcbiAgICAgIHBhcnRzLnB1c2gocGF0aC5zbGljZShzdGFydCkpO1xuICAgICAgYnJlYWs7XG4gICAgfSBlbHNlIHtcbiAgICAgIHBhcnRzLnB1c2gocGF0aC5zbGljZShzdGFydCwgaSkpO1xuICAgICAgd2hpbGUgKGkgPCBwYXRoLmxlbmd0aCAmJiBwYXRoW2ldID09PSBcIi9cIikge1xuICAgICAgICBpKys7XG4gICAgICB9XG4gICAgfVxuICB9XG5cbiAgZm9yICh2YXIgcGFydCwgdXAgPSAwLCBpID0gcGFydHMubGVuZ3RoIC0gMTsgaSA+PSAwOyBpLS0pIHtcbiAgICBwYXJ0ID0gcGFydHNbaV07XG4gICAgaWYgKHBhcnQgPT09ICcuJykge1xuICAgICAgcGFydHMuc3BsaWNlKGksIDEpO1xuICAgIH0gZWxzZSBpZiAocGFydCA9PT0gJy4uJykge1xuICAgICAgdXArKztcbiAgICB9IGVsc2UgaWYgKHVwID4gMCkge1xuICAgICAgaWYgKHBhcnQgPT09ICcnKSB7XG4gICAgICAgIC8vIFRoZSBmaXJzdCBwYXJ0IGlzIGJsYW5rIGlmIHRoZSBwYXRoIGlzIGFic29sdXRlLiBUcnlpbmcgdG8gZ29cbiAgICAgICAgLy8gYWJvdmUgdGhlIHJvb3QgaXMgYSBuby1vcC4gVGhlcmVmb3JlIHdlIGNhbiByZW1vdmUgYWxsICcuLicgcGFydHNcbiAgICAgICAgLy8gZGlyZWN0bHkgYWZ0ZXIgdGhlIHJvb3QuXG4gICAgICAgIHBhcnRzLnNwbGljZShpICsgMSwgdXApO1xuICAgICAgICB1cCA9IDA7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICBwYXJ0cy5zcGxpY2UoaSwgMik7XG4gICAgICAgIHVwLS07XG4gICAgICB9XG4gICAgfVxuICB9XG4gIHBhdGggPSBwYXJ0cy5qb2luKCcvJyk7XG5cbiAgaWYgKHBhdGggPT09ICcnKSB7XG4gICAgcGF0aCA9IGlzQWJzb2x1dGUgPyAnLycgOiAnLic7XG4gIH1cblxuICBpZiAodXJsKSB7XG4gICAgdXJsLnBhdGggPSBwYXRoO1xuICAgIHJldHVybiB1cmxHZW5lcmF0ZSh1cmwpO1xuICB9XG4gIHJldHVybiBwYXRoO1xufSk7XG5leHBvcnRzLm5vcm1hbGl6ZSA9IG5vcm1hbGl6ZTtcblxuLyoqXG4gKiBKb2lucyB0d28gcGF0aHMvVVJMcy5cbiAqXG4gKiBAcGFyYW0gYVJvb3QgVGhlIHJvb3QgcGF0aCBvciBVUkwuXG4gKiBAcGFyYW0gYVBhdGggVGhlIHBhdGggb3IgVVJMIHRvIGJlIGpvaW5lZCB3aXRoIHRoZSByb290LlxuICpcbiAqIC0gSWYgYVBhdGggaXMgYSBVUkwgb3IgYSBkYXRhIFVSSSwgYVBhdGggaXMgcmV0dXJuZWQsIHVubGVzcyBhUGF0aCBpcyBhXG4gKiAgIHNjaGVtZS1yZWxhdGl2ZSBVUkw6IFRoZW4gdGhlIHNjaGVtZSBvZiBhUm9vdCwgaWYgYW55LCBpcyBwcmVwZW5kZWRcbiAqICAgZmlyc3QuXG4gKiAtIE90aGVyd2lzZSBhUGF0aCBpcyBhIHBhdGguIElmIGFSb290IGlzIGEgVVJMLCB0aGVuIGl0cyBwYXRoIHBvcnRpb25cbiAqICAgaXMgdXBkYXRlZCB3aXRoIHRoZSByZXN1bHQgYW5kIGFSb290IGlzIHJldHVybmVkLiBPdGhlcndpc2UgdGhlIHJlc3VsdFxuICogICBpcyByZXR1cm5lZC5cbiAqICAgLSBJZiBhUGF0aCBpcyBhYnNvbHV0ZSwgdGhlIHJlc3VsdCBpcyBhUGF0aC5cbiAqICAgLSBPdGhlcndpc2UgdGhlIHR3byBwYXRocyBhcmUgam9pbmVkIHdpdGggYSBzbGFzaC5cbiAqIC0gSm9pbmluZyBmb3IgZXhhbXBsZSAnaHR0cDovLycgYW5kICd3d3cuZXhhbXBsZS5jb20nIGlzIGFsc28gc3VwcG9ydGVkLlxuICovXG5mdW5jdGlvbiBqb2luKGFSb290LCBhUGF0aCkge1xuICBpZiAoYVJvb3QgPT09IFwiXCIpIHtcbiAgICBhUm9vdCA9IFwiLlwiO1xuICB9XG4gIGlmIChhUGF0aCA9PT0gXCJcIikge1xuICAgIGFQYXRoID0gXCIuXCI7XG4gIH1cbiAgdmFyIGFQYXRoVXJsID0gdXJsUGFyc2UoYVBhdGgpO1xuICB2YXIgYVJvb3RVcmwgPSB1cmxQYXJzZShhUm9vdCk7XG4gIGlmIChhUm9vdFVybCkge1xuICAgIGFSb290ID0gYVJvb3RVcmwucGF0aCB8fCAnLyc7XG4gIH1cblxuICAvLyBgam9pbihmb28sICcvL3d3dy5leGFtcGxlLm9yZycpYFxuICBpZiAoYVBhdGhVcmwgJiYgIWFQYXRoVXJsLnNjaGVtZSkge1xuICAgIGlmIChhUm9vdFVybCkge1xuICAgICAgYVBhdGhVcmwuc2NoZW1lID0gYVJvb3RVcmwuc2NoZW1lO1xuICAgIH1cbiAgICByZXR1cm4gdXJsR2VuZXJhdGUoYVBhdGhVcmwpO1xuICB9XG5cbiAgaWYgKGFQYXRoVXJsIHx8IGFQYXRoLm1hdGNoKGRhdGFVcmxSZWdleHApKSB7XG4gICAgcmV0dXJuIGFQYXRoO1xuICB9XG5cbiAgLy8gYGpvaW4oJ2h0dHA6Ly8nLCAnd3d3LmV4YW1wbGUuY29tJylgXG4gIGlmIChhUm9vdFVybCAmJiAhYVJvb3RVcmwuaG9zdCAmJiAhYVJvb3RVcmwucGF0aCkge1xuICAgIGFSb290VXJsLmhvc3QgPSBhUGF0aDtcbiAgICByZXR1cm4gdXJsR2VuZXJhdGUoYVJvb3RVcmwpO1xuICB9XG5cbiAgdmFyIGpvaW5lZCA9IGFQYXRoLmNoYXJBdCgwKSA9PT0gJy8nXG4gICAgPyBhUGF0aFxuICAgIDogbm9ybWFsaXplKGFSb290LnJlcGxhY2UoL1xcLyskLywgJycpICsgJy8nICsgYVBhdGgpO1xuXG4gIGlmIChhUm9vdFVybCkge1xuICAgIGFSb290VXJsLnBhdGggPSBqb2luZWQ7XG4gICAgcmV0dXJuIHVybEdlbmVyYXRlKGFSb290VXJsKTtcbiAgfVxuICByZXR1cm4gam9pbmVkO1xufVxuZXhwb3J0cy5qb2luID0gam9pbjtcblxuZXhwb3J0cy5pc0Fic29sdXRlID0gZnVuY3Rpb24gKGFQYXRoKSB7XG4gIHJldHVybiBhUGF0aC5jaGFyQXQoMCkgPT09ICcvJyB8fCB1cmxSZWdleHAudGVzdChhUGF0aCk7XG59O1xuXG4vKipcbiAqIE1ha2UgYSBwYXRoIHJlbGF0aXZlIHRvIGEgVVJMIG9yIGFub3RoZXIgcGF0aC5cbiAqXG4gKiBAcGFyYW0gYVJvb3QgVGhlIHJvb3QgcGF0aCBvciBVUkwuXG4gKiBAcGFyYW0gYVBhdGggVGhlIHBhdGggb3IgVVJMIHRvIGJlIG1hZGUgcmVsYXRpdmUgdG8gYVJvb3QuXG4gKi9cbmZ1bmN0aW9uIHJlbGF0aXZlKGFSb290LCBhUGF0aCkge1xuICBpZiAoYVJvb3QgPT09IFwiXCIpIHtcbiAgICBhUm9vdCA9IFwiLlwiO1xuICB9XG5cbiAgYVJvb3QgPSBhUm9vdC5yZXBsYWNlKC9cXC8kLywgJycpO1xuXG4gIC8vIEl0IGlzIHBvc3NpYmxlIGZvciB0aGUgcGF0aCB0byBiZSBhYm92ZSB0aGUgcm9vdC4gSW4gdGhpcyBjYXNlLCBzaW1wbHlcbiAgLy8gY2hlY2tpbmcgd2hldGhlciB0aGUgcm9vdCBpcyBhIHByZWZpeCBvZiB0aGUgcGF0aCB3b24ndCB3b3JrLiBJbnN0ZWFkLCB3ZVxuICAvLyBuZWVkIHRvIHJlbW92ZSBjb21wb25lbnRzIGZyb20gdGhlIHJvb3Qgb25lIGJ5IG9uZSwgdW50aWwgZWl0aGVyIHdlIGZpbmRcbiAgLy8gYSBwcmVmaXggdGhhdCBmaXRzLCBvciB3ZSBydW4gb3V0IG9mIGNvbXBvbmVudHMgdG8gcmVtb3ZlLlxuICB2YXIgbGV2ZWwgPSAwO1xuICB3aGlsZSAoYVBhdGguaW5kZXhPZihhUm9vdCArICcvJykgIT09IDApIHtcbiAgICB2YXIgaW5kZXggPSBhUm9vdC5sYXN0SW5kZXhPZihcIi9cIik7XG4gICAgaWYgKGluZGV4IDwgMCkge1xuICAgICAgcmV0dXJuIGFQYXRoO1xuICAgIH1cblxuICAgIC8vIElmIHRoZSBvbmx5IHBhcnQgb2YgdGhlIHJvb3QgdGhhdCBpcyBsZWZ0IGlzIHRoZSBzY2hlbWUgKGkuZS4gaHR0cDovLyxcbiAgICAvLyBmaWxlOi8vLywgZXRjLiksIG9uZSBvciBtb3JlIHNsYXNoZXMgKC8pLCBvciBzaW1wbHkgbm90aGluZyBhdCBhbGwsIHdlXG4gICAgLy8gaGF2ZSBleGhhdXN0ZWQgYWxsIGNvbXBvbmVudHMsIHNvIHRoZSBwYXRoIGlzIG5vdCByZWxhdGl2ZSB0byB0aGUgcm9vdC5cbiAgICBhUm9vdCA9IGFSb290LnNsaWNlKDAsIGluZGV4KTtcbiAgICBpZiAoYVJvb3QubWF0Y2goL14oW15cXC9dKzpcXC8pP1xcLyokLykpIHtcbiAgICAgIHJldHVybiBhUGF0aDtcbiAgICB9XG5cbiAgICArK2xldmVsO1xuICB9XG5cbiAgLy8gTWFrZSBzdXJlIHdlIGFkZCBhIFwiLi4vXCIgZm9yIGVhY2ggY29tcG9uZW50IHdlIHJlbW92ZWQgZnJvbSB0aGUgcm9vdC5cbiAgcmV0dXJuIEFycmF5KGxldmVsICsgMSkuam9pbihcIi4uL1wiKSArIGFQYXRoLnN1YnN0cihhUm9vdC5sZW5ndGggKyAxKTtcbn1cbmV4cG9ydHMucmVsYXRpdmUgPSByZWxhdGl2ZTtcblxudmFyIHN1cHBvcnRzTnVsbFByb3RvID0gKGZ1bmN0aW9uICgpIHtcbiAgdmFyIG9iaiA9IE9iamVjdC5jcmVhdGUobnVsbCk7XG4gIHJldHVybiAhKCdfX3Byb3RvX18nIGluIG9iaik7XG59KCkpO1xuXG5mdW5jdGlvbiBpZGVudGl0eSAocykge1xuICByZXR1cm4gcztcbn1cblxuLyoqXG4gKiBCZWNhdXNlIGJlaGF2aW9yIGdvZXMgd2Fja3kgd2hlbiB5b3Ugc2V0IGBfX3Byb3RvX19gIG9uIG9iamVjdHMsIHdlXG4gKiBoYXZlIHRvIHByZWZpeCBhbGwgdGhlIHN0cmluZ3MgaW4gb3VyIHNldCB3aXRoIGFuIGFyYml0cmFyeSBjaGFyYWN0ZXIuXG4gKlxuICogU2VlIGh0dHBzOi8vZ2l0aHViLmNvbS9tb3ppbGxhL3NvdXJjZS1tYXAvcHVsbC8zMSBhbmRcbiAqIGh0dHBzOi8vZ2l0aHViLmNvbS9tb3ppbGxhL3NvdXJjZS1tYXAvaXNzdWVzLzMwXG4gKlxuICogQHBhcmFtIFN0cmluZyBhU3RyXG4gKi9cbmZ1bmN0aW9uIHRvU2V0U3RyaW5nKGFTdHIpIHtcbiAgaWYgKGlzUHJvdG9TdHJpbmcoYVN0cikpIHtcbiAgICByZXR1cm4gJyQnICsgYVN0cjtcbiAgfVxuXG4gIHJldHVybiBhU3RyO1xufVxuZXhwb3J0cy50b1NldFN0cmluZyA9IHN1cHBvcnRzTnVsbFByb3RvID8gaWRlbnRpdHkgOiB0b1NldFN0cmluZztcblxuZnVuY3Rpb24gZnJvbVNldFN0cmluZyhhU3RyKSB7XG4gIGlmIChpc1Byb3RvU3RyaW5nKGFTdHIpKSB7XG4gICAgcmV0dXJuIGFTdHIuc2xpY2UoMSk7XG4gIH1cblxuICByZXR1cm4gYVN0cjtcbn1cbmV4cG9ydHMuZnJvbVNldFN0cmluZyA9IHN1cHBvcnRzTnVsbFByb3RvID8gaWRlbnRpdHkgOiBmcm9tU2V0U3RyaW5nO1xuXG5mdW5jdGlvbiBpc1Byb3RvU3RyaW5nKHMpIHtcbiAgaWYgKCFzKSB7XG4gICAgcmV0dXJuIGZhbHNlO1xuICB9XG5cbiAgdmFyIGxlbmd0aCA9IHMubGVuZ3RoO1xuXG4gIGlmIChsZW5ndGggPCA5IC8qIFwiX19wcm90b19fXCIubGVuZ3RoICovKSB7XG4gICAgcmV0dXJuIGZhbHNlO1xuICB9XG5cbiAgaWYgKHMuY2hhckNvZGVBdChsZW5ndGggLSAxKSAhPT0gOTUgIC8qICdfJyAqLyB8fFxuICAgICAgcy5jaGFyQ29kZUF0KGxlbmd0aCAtIDIpICE9PSA5NSAgLyogJ18nICovIHx8XG4gICAgICBzLmNoYXJDb2RlQXQobGVuZ3RoIC0gMykgIT09IDExMSAvKiAnbycgKi8gfHxcbiAgICAgIHMuY2hhckNvZGVBdChsZW5ndGggLSA0KSAhPT0gMTE2IC8qICd0JyAqLyB8fFxuICAgICAgcy5jaGFyQ29kZUF0KGxlbmd0aCAtIDUpICE9PSAxMTEgLyogJ28nICovIHx8XG4gICAgICBzLmNoYXJDb2RlQXQobGVuZ3RoIC0gNikgIT09IDExNCAvKiAncicgKi8gfHxcbiAgICAgIHMuY2hhckNvZGVBdChsZW5ndGggLSA3KSAhPT0gMTEyIC8qICdwJyAqLyB8fFxuICAgICAgcy5jaGFyQ29kZUF0KGxlbmd0aCAtIDgpICE9PSA5NSAgLyogJ18nICovIHx8XG4gICAgICBzLmNoYXJDb2RlQXQobGVuZ3RoIC0gOSkgIT09IDk1ICAvKiAnXycgKi8pIHtcbiAgICByZXR1cm4gZmFsc2U7XG4gIH1cblxuICBmb3IgKHZhciBpID0gbGVuZ3RoIC0gMTA7IGkgPj0gMDsgaS0tKSB7XG4gICAgaWYgKHMuY2hhckNvZGVBdChpKSAhPT0gMzYgLyogJyQnICovKSB7XG4gICAgICByZXR1cm4gZmFsc2U7XG4gICAgfVxuICB9XG5cbiAgcmV0dXJuIHRydWU7XG59XG5cbi8qKlxuICogQ29tcGFyYXRvciBiZXR3ZWVuIHR3byBtYXBwaW5ncyB3aGVyZSB0aGUgb3JpZ2luYWwgcG9zaXRpb25zIGFyZSBjb21wYXJlZC5cbiAqXG4gKiBPcHRpb25hbGx5IHBhc3MgaW4gYHRydWVgIGFzIGBvbmx5Q29tcGFyZUdlbmVyYXRlZGAgdG8gY29uc2lkZXIgdHdvXG4gKiBtYXBwaW5ncyB3aXRoIHRoZSBzYW1lIG9yaWdpbmFsIHNvdXJjZS9saW5lL2NvbHVtbiwgYnV0IGRpZmZlcmVudCBnZW5lcmF0ZWRcbiAqIGxpbmUgYW5kIGNvbHVtbiB0aGUgc2FtZS4gVXNlZnVsIHdoZW4gc2VhcmNoaW5nIGZvciBhIG1hcHBpbmcgd2l0aCBhXG4gKiBzdHViYmVkIG91dCBtYXBwaW5nLlxuICovXG5mdW5jdGlvbiBjb21wYXJlQnlPcmlnaW5hbFBvc2l0aW9ucyhtYXBwaW5nQSwgbWFwcGluZ0IsIG9ubHlDb21wYXJlT3JpZ2luYWwpIHtcbiAgdmFyIGNtcCA9IHN0cmNtcChtYXBwaW5nQS5zb3VyY2UsIG1hcHBpbmdCLnNvdXJjZSk7XG4gIGlmIChjbXAgIT09IDApIHtcbiAgICByZXR1cm4gY21wO1xuICB9XG5cbiAgY21wID0gbWFwcGluZ0Eub3JpZ2luYWxMaW5lIC0gbWFwcGluZ0Iub3JpZ2luYWxMaW5lO1xuICBpZiAoY21wICE9PSAwKSB7XG4gICAgcmV0dXJuIGNtcDtcbiAgfVxuXG4gIGNtcCA9IG1hcHBpbmdBLm9yaWdpbmFsQ29sdW1uIC0gbWFwcGluZ0Iub3JpZ2luYWxDb2x1bW47XG4gIGlmIChjbXAgIT09IDAgfHwgb25seUNvbXBhcmVPcmlnaW5hbCkge1xuICAgIHJldHVybiBjbXA7XG4gIH1cblxuICBjbXAgPSBtYXBwaW5nQS5nZW5lcmF0ZWRDb2x1bW4gLSBtYXBwaW5nQi5nZW5lcmF0ZWRDb2x1bW47XG4gIGlmIChjbXAgIT09IDApIHtcbiAgICByZXR1cm4gY21wO1xuICB9XG5cbiAgY21wID0gbWFwcGluZ0EuZ2VuZXJhdGVkTGluZSAtIG1hcHBpbmdCLmdlbmVyYXRlZExpbmU7XG4gIGlmIChjbXAgIT09IDApIHtcbiAgICByZXR1cm4gY21wO1xuICB9XG5cbiAgcmV0dXJuIHN0cmNtcChtYXBwaW5nQS5uYW1lLCBtYXBwaW5nQi5uYW1lKTtcbn1cbmV4cG9ydHMuY29tcGFyZUJ5T3JpZ2luYWxQb3NpdGlvbnMgPSBjb21wYXJlQnlPcmlnaW5hbFBvc2l0aW9ucztcblxuZnVuY3Rpb24gY29tcGFyZUJ5T3JpZ2luYWxQb3NpdGlvbnNOb1NvdXJjZShtYXBwaW5nQSwgbWFwcGluZ0IsIG9ubHlDb21wYXJlT3JpZ2luYWwpIHtcbiAgdmFyIGNtcFxuXG4gIGNtcCA9IG1hcHBpbmdBLm9yaWdpbmFsTGluZSAtIG1hcHBpbmdCLm9yaWdpbmFsTGluZTtcbiAgaWYgKGNtcCAhPT0gMCkge1xuICAgIHJldHVybiBjbXA7XG4gIH1cblxuICBjbXAgPSBtYXBwaW5nQS5vcmlnaW5hbENvbHVtbiAtIG1hcHBpbmdCLm9yaWdpbmFsQ29sdW1uO1xuICBpZiAoY21wICE9PSAwIHx8IG9ubHlDb21wYXJlT3JpZ2luYWwpIHtcbiAgICByZXR1cm4gY21wO1xuICB9XG5cbiAgY21wID0gbWFwcGluZ0EuZ2VuZXJhdGVkQ29sdW1uIC0gbWFwcGluZ0IuZ2VuZXJhdGVkQ29sdW1uO1xuICBpZiAoY21wICE9PSAwKSB7XG4gICAgcmV0dXJuIGNtcDtcbiAgfVxuXG4gIGNtcCA9IG1hcHBpbmdBLmdlbmVyYXRlZExpbmUgLSBtYXBwaW5nQi5nZW5lcmF0ZWRMaW5lO1xuICBpZiAoY21wICE9PSAwKSB7XG4gICAgcmV0dXJuIGNtcDtcbiAgfVxuXG4gIHJldHVybiBzdHJjbXAobWFwcGluZ0EubmFtZSwgbWFwcGluZ0IubmFtZSk7XG59XG5leHBvcnRzLmNvbXBhcmVCeU9yaWdpbmFsUG9zaXRpb25zTm9Tb3VyY2UgPSBjb21wYXJlQnlPcmlnaW5hbFBvc2l0aW9uc05vU291cmNlO1xuXG4vKipcbiAqIENvbXBhcmF0b3IgYmV0d2VlbiB0d28gbWFwcGluZ3Mgd2l0aCBkZWZsYXRlZCBzb3VyY2UgYW5kIG5hbWUgaW5kaWNlcyB3aGVyZVxuICogdGhlIGdlbmVyYXRlZCBwb3NpdGlvbnMgYXJlIGNvbXBhcmVkLlxuICpcbiAqIE9wdGlvbmFsbHkgcGFzcyBpbiBgdHJ1ZWAgYXMgYG9ubHlDb21wYXJlR2VuZXJhdGVkYCB0byBjb25zaWRlciB0d29cbiAqIG1hcHBpbmdzIHdpdGggdGhlIHNhbWUgZ2VuZXJhdGVkIGxpbmUgYW5kIGNvbHVtbiwgYnV0IGRpZmZlcmVudFxuICogc291cmNlL25hbWUvb3JpZ2luYWwgbGluZSBhbmQgY29sdW1uIHRoZSBzYW1lLiBVc2VmdWwgd2hlbiBzZWFyY2hpbmcgZm9yIGFcbiAqIG1hcHBpbmcgd2l0aCBhIHN0dWJiZWQgb3V0IG1hcHBpbmcuXG4gKi9cbmZ1bmN0aW9uIGNvbXBhcmVCeUdlbmVyYXRlZFBvc2l0aW9uc0RlZmxhdGVkKG1hcHBpbmdBLCBtYXBwaW5nQiwgb25seUNvbXBhcmVHZW5lcmF0ZWQpIHtcbiAgdmFyIGNtcCA9IG1hcHBpbmdBLmdlbmVyYXRlZExpbmUgLSBtYXBwaW5nQi5nZW5lcmF0ZWRMaW5lO1xuICBpZiAoY21wICE9PSAwKSB7XG4gICAgcmV0dXJuIGNtcDtcbiAgfVxuXG4gIGNtcCA9IG1hcHBpbmdBLmdlbmVyYXRlZENvbHVtbiAtIG1hcHBpbmdCLmdlbmVyYXRlZENvbHVtbjtcbiAgaWYgKGNtcCAhPT0gMCB8fCBvbmx5Q29tcGFyZUdlbmVyYXRlZCkge1xuICAgIHJldHVybiBjbXA7XG4gIH1cblxuICBjbXAgPSBzdHJjbXAobWFwcGluZ0Euc291cmNlLCBtYXBwaW5nQi5zb3VyY2UpO1xuICBpZiAoY21wICE9PSAwKSB7XG4gICAgcmV0dXJuIGNtcDtcbiAgfVxuXG4gIGNtcCA9IG1hcHBpbmdBLm9yaWdpbmFsTGluZSAtIG1hcHBpbmdCLm9yaWdpbmFsTGluZTtcbiAgaWYgKGNtcCAhPT0gMCkge1xuICAgIHJldHVybiBjbXA7XG4gIH1cblxuICBjbXAgPSBtYXBwaW5nQS5vcmlnaW5hbENvbHVtbiAtIG1hcHBpbmdCLm9yaWdpbmFsQ29sdW1uO1xuICBpZiAoY21wICE9PSAwKSB7XG4gICAgcmV0dXJuIGNtcDtcbiAgfVxuXG4gIHJldHVybiBzdHJjbXAobWFwcGluZ0EubmFtZSwgbWFwcGluZ0IubmFtZSk7XG59XG5leHBvcnRzLmNvbXBhcmVCeUdlbmVyYXRlZFBvc2l0aW9uc0RlZmxhdGVkID0gY29tcGFyZUJ5R2VuZXJhdGVkUG9zaXRpb25zRGVmbGF0ZWQ7XG5cbmZ1bmN0aW9uIGNvbXBhcmVCeUdlbmVyYXRlZFBvc2l0aW9uc0RlZmxhdGVkTm9MaW5lKG1hcHBpbmdBLCBtYXBwaW5nQiwgb25seUNvbXBhcmVHZW5lcmF0ZWQpIHtcbiAgdmFyIGNtcCA9IG1hcHBpbmdBLmdlbmVyYXRlZENvbHVtbiAtIG1hcHBpbmdCLmdlbmVyYXRlZENvbHVtbjtcbiAgaWYgKGNtcCAhPT0gMCB8fCBvbmx5Q29tcGFyZUdlbmVyYXRlZCkge1xuICAgIHJldHVybiBjbXA7XG4gIH1cblxuICBjbXAgPSBzdHJjbXAobWFwcGluZ0Euc291cmNlLCBtYXBwaW5nQi5zb3VyY2UpO1xuICBpZiAoY21wICE9PSAwKSB7XG4gICAgcmV0dXJuIGNtcDtcbiAgfVxuXG4gIGNtcCA9IG1hcHBpbmdBLm9yaWdpbmFsTGluZSAtIG1hcHBpbmdCLm9yaWdpbmFsTGluZTtcbiAgaWYgKGNtcCAhPT0gMCkge1xuICAgIHJldHVybiBjbXA7XG4gIH1cblxuICBjbXAgPSBtYXBwaW5nQS5vcmlnaW5hbENvbHVtbiAtIG1hcHBpbmdCLm9yaWdpbmFsQ29sdW1uO1xuICBpZiAoY21wICE9PSAwKSB7XG4gICAgcmV0dXJuIGNtcDtcbiAgfVxuXG4gIHJldHVybiBzdHJjbXAobWFwcGluZ0EubmFtZSwgbWFwcGluZ0IubmFtZSk7XG59XG5leHBvcnRzLmNvbXBhcmVCeUdlbmVyYXRlZFBvc2l0aW9uc0RlZmxhdGVkTm9MaW5lID0gY29tcGFyZUJ5R2VuZXJhdGVkUG9zaXRpb25zRGVmbGF0ZWROb0xpbmU7XG5cbmZ1bmN0aW9uIHN0cmNtcChhU3RyMSwgYVN0cjIpIHtcbiAgaWYgKGFTdHIxID09PSBhU3RyMikge1xuICAgIHJldHVybiAwO1xuICB9XG5cbiAgaWYgKGFTdHIxID09PSBudWxsKSB7XG4gICAgcmV0dXJuIDE7IC8vIGFTdHIyICE9PSBudWxsXG4gIH1cblxuICBpZiAoYVN0cjIgPT09IG51bGwpIHtcbiAgICByZXR1cm4gLTE7IC8vIGFTdHIxICE9PSBudWxsXG4gIH1cblxuICBpZiAoYVN0cjEgPiBhU3RyMikge1xuICAgIHJldHVybiAxO1xuICB9XG5cbiAgcmV0dXJuIC0xO1xufVxuXG4vKipcbiAqIENvbXBhcmF0b3IgYmV0d2VlbiB0d28gbWFwcGluZ3Mgd2l0aCBpbmZsYXRlZCBzb3VyY2UgYW5kIG5hbWUgc3RyaW5ncyB3aGVyZVxuICogdGhlIGdlbmVyYXRlZCBwb3NpdGlvbnMgYXJlIGNvbXBhcmVkLlxuICovXG5mdW5jdGlvbiBjb21wYXJlQnlHZW5lcmF0ZWRQb3NpdGlvbnNJbmZsYXRlZChtYXBwaW5nQSwgbWFwcGluZ0IpIHtcbiAgdmFyIGNtcCA9IG1hcHBpbmdBLmdlbmVyYXRlZExpbmUgLSBtYXBwaW5nQi5nZW5lcmF0ZWRMaW5lO1xuICBpZiAoY21wICE9PSAwKSB7XG4gICAgcmV0dXJuIGNtcDtcbiAgfVxuXG4gIGNtcCA9IG1hcHBpbmdBLmdlbmVyYXRlZENvbHVtbiAtIG1hcHBpbmdCLmdlbmVyYXRlZENvbHVtbjtcbiAgaWYgKGNtcCAhPT0gMCkge1xuICAgIHJldHVybiBjbXA7XG4gIH1cblxuICBjbXAgPSBzdHJjbXAobWFwcGluZ0Euc291cmNlLCBtYXBwaW5nQi5zb3VyY2UpO1xuICBpZiAoY21wICE9PSAwKSB7XG4gICAgcmV0dXJuIGNtcDtcbiAgfVxuXG4gIGNtcCA9IG1hcHBpbmdBLm9yaWdpbmFsTGluZSAtIG1hcHBpbmdCLm9yaWdpbmFsTGluZTtcbiAgaWYgKGNtcCAhPT0gMCkge1xuICAgIHJldHVybiBjbXA7XG4gIH1cblxuICBjbXAgPSBtYXBwaW5nQS5vcmlnaW5hbENvbHVtbiAtIG1hcHBpbmdCLm9yaWdpbmFsQ29sdW1uO1xuICBpZiAoY21wICE9PSAwKSB7XG4gICAgcmV0dXJuIGNtcDtcbiAgfVxuXG4gIHJldHVybiBzdHJjbXAobWFwcGluZ0EubmFtZSwgbWFwcGluZ0IubmFtZSk7XG59XG5leHBvcnRzLmNvbXBhcmVCeUdlbmVyYXRlZFBvc2l0aW9uc0luZmxhdGVkID0gY29tcGFyZUJ5R2VuZXJhdGVkUG9zaXRpb25zSW5mbGF0ZWQ7XG5cbi8qKlxuICogU3RyaXAgYW55IEpTT04gWFNTSSBhdm9pZGFuY2UgcHJlZml4IGZyb20gdGhlIHN0cmluZyAoYXMgZG9jdW1lbnRlZFxuICogaW4gdGhlIHNvdXJjZSBtYXBzIHNwZWNpZmljYXRpb24pLCBhbmQgdGhlbiBwYXJzZSB0aGUgc3RyaW5nIGFzXG4gKiBKU09OLlxuICovXG5mdW5jdGlvbiBwYXJzZVNvdXJjZU1hcElucHV0KHN0cikge1xuICByZXR1cm4gSlNPTi5wYXJzZShzdHIucmVwbGFjZSgvXlxcKV19J1teXFxuXSpcXG4vLCAnJykpO1xufVxuZXhwb3J0cy5wYXJzZVNvdXJjZU1hcElucHV0ID0gcGFyc2VTb3VyY2VNYXBJbnB1dDtcblxuLyoqXG4gKiBDb21wdXRlIHRoZSBVUkwgb2YgYSBzb3VyY2UgZ2l2ZW4gdGhlIHRoZSBzb3VyY2Ugcm9vdCwgdGhlIHNvdXJjZSdzXG4gKiBVUkwsIGFuZCB0aGUgc291cmNlIG1hcCdzIFVSTC5cbiAqL1xuZnVuY3Rpb24gY29tcHV0ZVNvdXJjZVVSTChzb3VyY2VSb290LCBzb3VyY2VVUkwsIHNvdXJjZU1hcFVSTCkge1xuICBzb3VyY2VVUkwgPSBzb3VyY2VVUkwgfHwgJyc7XG5cbiAgaWYgKHNvdXJjZVJvb3QpIHtcbiAgICAvLyBUaGlzIGZvbGxvd3Mgd2hhdCBDaHJvbWUgZG9lcy5cbiAgICBpZiAoc291cmNlUm9vdFtzb3VyY2VSb290Lmxlbmd0aCAtIDFdICE9PSAnLycgJiYgc291cmNlVVJMWzBdICE9PSAnLycpIHtcbiAgICAgIHNvdXJjZVJvb3QgKz0gJy8nO1xuICAgIH1cbiAgICAvLyBUaGUgc3BlYyBzYXlzOlxuICAgIC8vICAgTGluZSA0OiBBbiBvcHRpb25hbCBzb3VyY2Ugcm9vdCwgdXNlZnVsIGZvciByZWxvY2F0aW5nIHNvdXJjZVxuICAgIC8vICAgZmlsZXMgb24gYSBzZXJ2ZXIgb3IgcmVtb3ZpbmcgcmVwZWF0ZWQgdmFsdWVzIGluIHRoZVxuICAgIC8vICAgXHUyMDFDc291cmNlc1x1MjAxRCBlbnRyeS4gIFRoaXMgdmFsdWUgaXMgcHJlcGVuZGVkIHRvIHRoZSBpbmRpdmlkdWFsXG4gICAgLy8gICBlbnRyaWVzIGluIHRoZSBcdTIwMUNzb3VyY2VcdTIwMUQgZmllbGQuXG4gICAgc291cmNlVVJMID0gc291cmNlUm9vdCArIHNvdXJjZVVSTDtcbiAgfVxuXG4gIC8vIEhpc3RvcmljYWxseSwgU291cmNlTWFwQ29uc3VtZXIgZGlkIG5vdCB0YWtlIHRoZSBzb3VyY2VNYXBVUkwgYXNcbiAgLy8gYSBwYXJhbWV0ZXIuICBUaGlzIG1vZGUgaXMgc3RpbGwgc29tZXdoYXQgc3VwcG9ydGVkLCB3aGljaCBpcyB3aHlcbiAgLy8gdGhpcyBjb2RlIGJsb2NrIGlzIGNvbmRpdGlvbmFsLiAgSG93ZXZlciwgaXQncyBwcmVmZXJhYmxlIHRvIHBhc3NcbiAgLy8gdGhlIHNvdXJjZSBtYXAgVVJMIHRvIFNvdXJjZU1hcENvbnN1bWVyLCBzbyB0aGF0IHRoaXMgZnVuY3Rpb25cbiAgLy8gY2FuIGltcGxlbWVudCB0aGUgc291cmNlIFVSTCByZXNvbHV0aW9uIGFsZ29yaXRobSBhcyBvdXRsaW5lZCBpblxuICAvLyB0aGUgc3BlYy4gIFRoaXMgYmxvY2sgaXMgYmFzaWNhbGx5IHRoZSBlcXVpdmFsZW50IG9mOlxuICAvLyAgICBuZXcgVVJMKHNvdXJjZVVSTCwgc291cmNlTWFwVVJMKS50b1N0cmluZygpXG4gIC8vIC4uLiBleGNlcHQgaXQgYXZvaWRzIHVzaW5nIFVSTCwgd2hpY2ggd2Fzbid0IGF2YWlsYWJsZSBpbiB0aGVcbiAgLy8gb2xkZXIgcmVsZWFzZXMgb2Ygbm9kZSBzdGlsbCBzdXBwb3J0ZWQgYnkgdGhpcyBsaWJyYXJ5LlxuICAvL1xuICAvLyBUaGUgc3BlYyBzYXlzOlxuICAvLyAgIElmIHRoZSBzb3VyY2VzIGFyZSBub3QgYWJzb2x1dGUgVVJMcyBhZnRlciBwcmVwZW5kaW5nIG9mIHRoZVxuICAvLyAgIFx1MjAxQ3NvdXJjZVJvb3RcdTIwMUQsIHRoZSBzb3VyY2VzIGFyZSByZXNvbHZlZCByZWxhdGl2ZSB0byB0aGVcbiAgLy8gICBTb3VyY2VNYXAgKGxpa2UgcmVzb2x2aW5nIHNjcmlwdCBzcmMgaW4gYSBodG1sIGRvY3VtZW50KS5cbiAgaWYgKHNvdXJjZU1hcFVSTCkge1xuICAgIHZhciBwYXJzZWQgPSB1cmxQYXJzZShzb3VyY2VNYXBVUkwpO1xuICAgIGlmICghcGFyc2VkKSB7XG4gICAgICB0aHJvdyBuZXcgRXJyb3IoXCJzb3VyY2VNYXBVUkwgY291bGQgbm90IGJlIHBhcnNlZFwiKTtcbiAgICB9XG4gICAgaWYgKHBhcnNlZC5wYXRoKSB7XG4gICAgICAvLyBTdHJpcCB0aGUgbGFzdCBwYXRoIGNvbXBvbmVudCwgYnV0IGtlZXAgdGhlIFwiL1wiLlxuICAgICAgdmFyIGluZGV4ID0gcGFyc2VkLnBhdGgubGFzdEluZGV4T2YoJy8nKTtcbiAgICAgIGlmIChpbmRleCA+PSAwKSB7XG4gICAgICAgIHBhcnNlZC5wYXRoID0gcGFyc2VkLnBhdGguc3Vic3RyaW5nKDAsIGluZGV4ICsgMSk7XG4gICAgICB9XG4gICAgfVxuICAgIHNvdXJjZVVSTCA9IGpvaW4odXJsR2VuZXJhdGUocGFyc2VkKSwgc291cmNlVVJMKTtcbiAgfVxuXG4gIHJldHVybiBub3JtYWxpemUoc291cmNlVVJMKTtcbn1cbmV4cG9ydHMuY29tcHV0ZVNvdXJjZVVSTCA9IGNvbXB1dGVTb3VyY2VVUkw7XG4iLCAiLyogLSotIE1vZGU6IGpzOyBqcy1pbmRlbnQtbGV2ZWw6IDI7IC0qLSAqL1xuLypcbiAqIENvcHlyaWdodCAyMDExIE1vemlsbGEgRm91bmRhdGlvbiBhbmQgY29udHJpYnV0b3JzXG4gKiBMaWNlbnNlZCB1bmRlciB0aGUgTmV3IEJTRCBsaWNlbnNlLiBTZWUgTElDRU5TRSBvcjpcbiAqIGh0dHA6Ly9vcGVuc291cmNlLm9yZy9saWNlbnNlcy9CU0QtMy1DbGF1c2VcbiAqL1xuXG52YXIgdXRpbCA9IHJlcXVpcmUoJy4vdXRpbCcpO1xudmFyIGhhcyA9IE9iamVjdC5wcm90b3R5cGUuaGFzT3duUHJvcGVydHk7XG52YXIgaGFzTmF0aXZlTWFwID0gdHlwZW9mIE1hcCAhPT0gXCJ1bmRlZmluZWRcIjtcblxuLyoqXG4gKiBBIGRhdGEgc3RydWN0dXJlIHdoaWNoIGlzIGEgY29tYmluYXRpb24gb2YgYW4gYXJyYXkgYW5kIGEgc2V0LiBBZGRpbmcgYSBuZXdcbiAqIG1lbWJlciBpcyBPKDEpLCB0ZXN0aW5nIGZvciBtZW1iZXJzaGlwIGlzIE8oMSksIGFuZCBmaW5kaW5nIHRoZSBpbmRleCBvZiBhblxuICogZWxlbWVudCBpcyBPKDEpLiBSZW1vdmluZyBlbGVtZW50cyBmcm9tIHRoZSBzZXQgaXMgbm90IHN1cHBvcnRlZC4gT25seVxuICogc3RyaW5ncyBhcmUgc3VwcG9ydGVkIGZvciBtZW1iZXJzaGlwLlxuICovXG5mdW5jdGlvbiBBcnJheVNldCgpIHtcbiAgdGhpcy5fYXJyYXkgPSBbXTtcbiAgdGhpcy5fc2V0ID0gaGFzTmF0aXZlTWFwID8gbmV3IE1hcCgpIDogT2JqZWN0LmNyZWF0ZShudWxsKTtcbn1cblxuLyoqXG4gKiBTdGF0aWMgbWV0aG9kIGZvciBjcmVhdGluZyBBcnJheVNldCBpbnN0YW5jZXMgZnJvbSBhbiBleGlzdGluZyBhcnJheS5cbiAqL1xuQXJyYXlTZXQuZnJvbUFycmF5ID0gZnVuY3Rpb24gQXJyYXlTZXRfZnJvbUFycmF5KGFBcnJheSwgYUFsbG93RHVwbGljYXRlcykge1xuICB2YXIgc2V0ID0gbmV3IEFycmF5U2V0KCk7XG4gIGZvciAodmFyIGkgPSAwLCBsZW4gPSBhQXJyYXkubGVuZ3RoOyBpIDwgbGVuOyBpKyspIHtcbiAgICBzZXQuYWRkKGFBcnJheVtpXSwgYUFsbG93RHVwbGljYXRlcyk7XG4gIH1cbiAgcmV0dXJuIHNldDtcbn07XG5cbi8qKlxuICogUmV0dXJuIGhvdyBtYW55IHVuaXF1ZSBpdGVtcyBhcmUgaW4gdGhpcyBBcnJheVNldC4gSWYgZHVwbGljYXRlcyBoYXZlIGJlZW5cbiAqIGFkZGVkLCB0aGFuIHRob3NlIGRvIG5vdCBjb3VudCB0b3dhcmRzIHRoZSBzaXplLlxuICpcbiAqIEByZXR1cm5zIE51bWJlclxuICovXG5BcnJheVNldC5wcm90b3R5cGUuc2l6ZSA9IGZ1bmN0aW9uIEFycmF5U2V0X3NpemUoKSB7XG4gIHJldHVybiBoYXNOYXRpdmVNYXAgPyB0aGlzLl9zZXQuc2l6ZSA6IE9iamVjdC5nZXRPd25Qcm9wZXJ0eU5hbWVzKHRoaXMuX3NldCkubGVuZ3RoO1xufTtcblxuLyoqXG4gKiBBZGQgdGhlIGdpdmVuIHN0cmluZyB0byB0aGlzIHNldC5cbiAqXG4gKiBAcGFyYW0gU3RyaW5nIGFTdHJcbiAqL1xuQXJyYXlTZXQucHJvdG90eXBlLmFkZCA9IGZ1bmN0aW9uIEFycmF5U2V0X2FkZChhU3RyLCBhQWxsb3dEdXBsaWNhdGVzKSB7XG4gIHZhciBzU3RyID0gaGFzTmF0aXZlTWFwID8gYVN0ciA6IHV0aWwudG9TZXRTdHJpbmcoYVN0cik7XG4gIHZhciBpc0R1cGxpY2F0ZSA9IGhhc05hdGl2ZU1hcCA/IHRoaXMuaGFzKGFTdHIpIDogaGFzLmNhbGwodGhpcy5fc2V0LCBzU3RyKTtcbiAgdmFyIGlkeCA9IHRoaXMuX2FycmF5Lmxlbmd0aDtcbiAgaWYgKCFpc0R1cGxpY2F0ZSB8fCBhQWxsb3dEdXBsaWNhdGVzKSB7XG4gICAgdGhpcy5fYXJyYXkucHVzaChhU3RyKTtcbiAgfVxuICBpZiAoIWlzRHVwbGljYXRlKSB7XG4gICAgaWYgKGhhc05hdGl2ZU1hcCkge1xuICAgICAgdGhpcy5fc2V0LnNldChhU3RyLCBpZHgpO1xuICAgIH0gZWxzZSB7XG4gICAgICB0aGlzLl9zZXRbc1N0cl0gPSBpZHg7XG4gICAgfVxuICB9XG59O1xuXG4vKipcbiAqIElzIHRoZSBnaXZlbiBzdHJpbmcgYSBtZW1iZXIgb2YgdGhpcyBzZXQ/XG4gKlxuICogQHBhcmFtIFN0cmluZyBhU3RyXG4gKi9cbkFycmF5U2V0LnByb3RvdHlwZS5oYXMgPSBmdW5jdGlvbiBBcnJheVNldF9oYXMoYVN0cikge1xuICBpZiAoaGFzTmF0aXZlTWFwKSB7XG4gICAgcmV0dXJuIHRoaXMuX3NldC5oYXMoYVN0cik7XG4gIH0gZWxzZSB7XG4gICAgdmFyIHNTdHIgPSB1dGlsLnRvU2V0U3RyaW5nKGFTdHIpO1xuICAgIHJldHVybiBoYXMuY2FsbCh0aGlzLl9zZXQsIHNTdHIpO1xuICB9XG59O1xuXG4vKipcbiAqIFdoYXQgaXMgdGhlIGluZGV4IG9mIHRoZSBnaXZlbiBzdHJpbmcgaW4gdGhlIGFycmF5P1xuICpcbiAqIEBwYXJhbSBTdHJpbmcgYVN0clxuICovXG5BcnJheVNldC5wcm90b3R5cGUuaW5kZXhPZiA9IGZ1bmN0aW9uIEFycmF5U2V0X2luZGV4T2YoYVN0cikge1xuICBpZiAoaGFzTmF0aXZlTWFwKSB7XG4gICAgdmFyIGlkeCA9IHRoaXMuX3NldC5nZXQoYVN0cik7XG4gICAgaWYgKGlkeCA+PSAwKSB7XG4gICAgICAgIHJldHVybiBpZHg7XG4gICAgfVxuICB9IGVsc2Uge1xuICAgIHZhciBzU3RyID0gdXRpbC50b1NldFN0cmluZyhhU3RyKTtcbiAgICBpZiAoaGFzLmNhbGwodGhpcy5fc2V0LCBzU3RyKSkge1xuICAgICAgcmV0dXJuIHRoaXMuX3NldFtzU3RyXTtcbiAgICB9XG4gIH1cblxuICB0aHJvdyBuZXcgRXJyb3IoJ1wiJyArIGFTdHIgKyAnXCIgaXMgbm90IGluIHRoZSBzZXQuJyk7XG59O1xuXG4vKipcbiAqIFdoYXQgaXMgdGhlIGVsZW1lbnQgYXQgdGhlIGdpdmVuIGluZGV4P1xuICpcbiAqIEBwYXJhbSBOdW1iZXIgYUlkeFxuICovXG5BcnJheVNldC5wcm90b3R5cGUuYXQgPSBmdW5jdGlvbiBBcnJheVNldF9hdChhSWR4KSB7XG4gIGlmIChhSWR4ID49IDAgJiYgYUlkeCA8IHRoaXMuX2FycmF5Lmxlbmd0aCkge1xuICAgIHJldHVybiB0aGlzLl9hcnJheVthSWR4XTtcbiAgfVxuICB0aHJvdyBuZXcgRXJyb3IoJ05vIGVsZW1lbnQgaW5kZXhlZCBieSAnICsgYUlkeCk7XG59O1xuXG4vKipcbiAqIFJldHVybnMgdGhlIGFycmF5IHJlcHJlc2VudGF0aW9uIG9mIHRoaXMgc2V0ICh3aGljaCBoYXMgdGhlIHByb3BlciBpbmRpY2VzXG4gKiBpbmRpY2F0ZWQgYnkgaW5kZXhPZikuIE5vdGUgdGhhdCB0aGlzIGlzIGEgY29weSBvZiB0aGUgaW50ZXJuYWwgYXJyYXkgdXNlZFxuICogZm9yIHN0b3JpbmcgdGhlIG1lbWJlcnMgc28gdGhhdCBubyBvbmUgY2FuIG1lc3Mgd2l0aCBpbnRlcm5hbCBzdGF0ZS5cbiAqL1xuQXJyYXlTZXQucHJvdG90eXBlLnRvQXJyYXkgPSBmdW5jdGlvbiBBcnJheVNldF90b0FycmF5KCkge1xuICByZXR1cm4gdGhpcy5fYXJyYXkuc2xpY2UoKTtcbn07XG5cbmV4cG9ydHMuQXJyYXlTZXQgPSBBcnJheVNldDtcbiIsICIvKiAtKi0gTW9kZToganM7IGpzLWluZGVudC1sZXZlbDogMjsgLSotICovXG4vKlxuICogQ29weXJpZ2h0IDIwMTQgTW96aWxsYSBGb3VuZGF0aW9uIGFuZCBjb250cmlidXRvcnNcbiAqIExpY2Vuc2VkIHVuZGVyIHRoZSBOZXcgQlNEIGxpY2Vuc2UuIFNlZSBMSUNFTlNFIG9yOlxuICogaHR0cDovL29wZW5zb3VyY2Uub3JnL2xpY2Vuc2VzL0JTRC0zLUNsYXVzZVxuICovXG5cbnZhciB1dGlsID0gcmVxdWlyZSgnLi91dGlsJyk7XG5cbi8qKlxuICogRGV0ZXJtaW5lIHdoZXRoZXIgbWFwcGluZ0IgaXMgYWZ0ZXIgbWFwcGluZ0Egd2l0aCByZXNwZWN0IHRvIGdlbmVyYXRlZFxuICogcG9zaXRpb24uXG4gKi9cbmZ1bmN0aW9uIGdlbmVyYXRlZFBvc2l0aW9uQWZ0ZXIobWFwcGluZ0EsIG1hcHBpbmdCKSB7XG4gIC8vIE9wdGltaXplZCBmb3IgbW9zdCBjb21tb24gY2FzZVxuICB2YXIgbGluZUEgPSBtYXBwaW5nQS5nZW5lcmF0ZWRMaW5lO1xuICB2YXIgbGluZUIgPSBtYXBwaW5nQi5nZW5lcmF0ZWRMaW5lO1xuICB2YXIgY29sdW1uQSA9IG1hcHBpbmdBLmdlbmVyYXRlZENvbHVtbjtcbiAgdmFyIGNvbHVtbkIgPSBtYXBwaW5nQi5nZW5lcmF0ZWRDb2x1bW47XG4gIHJldHVybiBsaW5lQiA+IGxpbmVBIHx8IGxpbmVCID09IGxpbmVBICYmIGNvbHVtbkIgPj0gY29sdW1uQSB8fFxuICAgICAgICAgdXRpbC5jb21wYXJlQnlHZW5lcmF0ZWRQb3NpdGlvbnNJbmZsYXRlZChtYXBwaW5nQSwgbWFwcGluZ0IpIDw9IDA7XG59XG5cbi8qKlxuICogQSBkYXRhIHN0cnVjdHVyZSB0byBwcm92aWRlIGEgc29ydGVkIHZpZXcgb2YgYWNjdW11bGF0ZWQgbWFwcGluZ3MgaW4gYVxuICogcGVyZm9ybWFuY2UgY29uc2Npb3VzIG1hbm5lci4gSXQgdHJhZGVzIGEgbmVnbGliYWJsZSBvdmVyaGVhZCBpbiBnZW5lcmFsXG4gKiBjYXNlIGZvciBhIGxhcmdlIHNwZWVkdXAgaW4gY2FzZSBvZiBtYXBwaW5ncyBiZWluZyBhZGRlZCBpbiBvcmRlci5cbiAqL1xuZnVuY3Rpb24gTWFwcGluZ0xpc3QoKSB7XG4gIHRoaXMuX2FycmF5ID0gW107XG4gIHRoaXMuX3NvcnRlZCA9IHRydWU7XG4gIC8vIFNlcnZlcyBhcyBpbmZpbXVtXG4gIHRoaXMuX2xhc3QgPSB7Z2VuZXJhdGVkTGluZTogLTEsIGdlbmVyYXRlZENvbHVtbjogMH07XG59XG5cbi8qKlxuICogSXRlcmF0ZSB0aHJvdWdoIGludGVybmFsIGl0ZW1zLiBUaGlzIG1ldGhvZCB0YWtlcyB0aGUgc2FtZSBhcmd1bWVudHMgdGhhdFxuICogYEFycmF5LnByb3RvdHlwZS5mb3JFYWNoYCB0YWtlcy5cbiAqXG4gKiBOT1RFOiBUaGUgb3JkZXIgb2YgdGhlIG1hcHBpbmdzIGlzIE5PVCBndWFyYW50ZWVkLlxuICovXG5NYXBwaW5nTGlzdC5wcm90b3R5cGUudW5zb3J0ZWRGb3JFYWNoID1cbiAgZnVuY3Rpb24gTWFwcGluZ0xpc3RfZm9yRWFjaChhQ2FsbGJhY2ssIGFUaGlzQXJnKSB7XG4gICAgdGhpcy5fYXJyYXkuZm9yRWFjaChhQ2FsbGJhY2ssIGFUaGlzQXJnKTtcbiAgfTtcblxuLyoqXG4gKiBBZGQgdGhlIGdpdmVuIHNvdXJjZSBtYXBwaW5nLlxuICpcbiAqIEBwYXJhbSBPYmplY3QgYU1hcHBpbmdcbiAqL1xuTWFwcGluZ0xpc3QucHJvdG90eXBlLmFkZCA9IGZ1bmN0aW9uIE1hcHBpbmdMaXN0X2FkZChhTWFwcGluZykge1xuICBpZiAoZ2VuZXJhdGVkUG9zaXRpb25BZnRlcih0aGlzLl9sYXN0LCBhTWFwcGluZykpIHtcbiAgICB0aGlzLl9sYXN0ID0gYU1hcHBpbmc7XG4gICAgdGhpcy5fYXJyYXkucHVzaChhTWFwcGluZyk7XG4gIH0gZWxzZSB7XG4gICAgdGhpcy5fc29ydGVkID0gZmFsc2U7XG4gICAgdGhpcy5fYXJyYXkucHVzaChhTWFwcGluZyk7XG4gIH1cbn07XG5cbi8qKlxuICogUmV0dXJucyB0aGUgZmxhdCwgc29ydGVkIGFycmF5IG9mIG1hcHBpbmdzLiBUaGUgbWFwcGluZ3MgYXJlIHNvcnRlZCBieVxuICogZ2VuZXJhdGVkIHBvc2l0aW9uLlxuICpcbiAqIFdBUk5JTkc6IFRoaXMgbWV0aG9kIHJldHVybnMgaW50ZXJuYWwgZGF0YSB3aXRob3V0IGNvcHlpbmcsIGZvclxuICogcGVyZm9ybWFuY2UuIFRoZSByZXR1cm4gdmFsdWUgbXVzdCBOT1QgYmUgbXV0YXRlZCwgYW5kIHNob3VsZCBiZSB0cmVhdGVkIGFzXG4gKiBhbiBpbW11dGFibGUgYm9ycm93LiBJZiB5b3Ugd2FudCB0byB0YWtlIG93bmVyc2hpcCwgeW91IG11c3QgbWFrZSB5b3VyIG93blxuICogY29weS5cbiAqL1xuTWFwcGluZ0xpc3QucHJvdG90eXBlLnRvQXJyYXkgPSBmdW5jdGlvbiBNYXBwaW5nTGlzdF90b0FycmF5KCkge1xuICBpZiAoIXRoaXMuX3NvcnRlZCkge1xuICAgIHRoaXMuX2FycmF5LnNvcnQodXRpbC5jb21wYXJlQnlHZW5lcmF0ZWRQb3NpdGlvbnNJbmZsYXRlZCk7XG4gICAgdGhpcy5fc29ydGVkID0gdHJ1ZTtcbiAgfVxuICByZXR1cm4gdGhpcy5fYXJyYXk7XG59O1xuXG5leHBvcnRzLk1hcHBpbmdMaXN0ID0gTWFwcGluZ0xpc3Q7XG4iLCAiLyogLSotIE1vZGU6IGpzOyBqcy1pbmRlbnQtbGV2ZWw6IDI7IC0qLSAqL1xuLypcbiAqIENvcHlyaWdodCAyMDExIE1vemlsbGEgRm91bmRhdGlvbiBhbmQgY29udHJpYnV0b3JzXG4gKiBMaWNlbnNlZCB1bmRlciB0aGUgTmV3IEJTRCBsaWNlbnNlLiBTZWUgTElDRU5TRSBvcjpcbiAqIGh0dHA6Ly9vcGVuc291cmNlLm9yZy9saWNlbnNlcy9CU0QtMy1DbGF1c2VcbiAqL1xuXG52YXIgYmFzZTY0VkxRID0gcmVxdWlyZSgnLi9iYXNlNjQtdmxxJyk7XG52YXIgdXRpbCA9IHJlcXVpcmUoJy4vdXRpbCcpO1xudmFyIEFycmF5U2V0ID0gcmVxdWlyZSgnLi9hcnJheS1zZXQnKS5BcnJheVNldDtcbnZhciBNYXBwaW5nTGlzdCA9IHJlcXVpcmUoJy4vbWFwcGluZy1saXN0JykuTWFwcGluZ0xpc3Q7XG5cbi8qKlxuICogQW4gaW5zdGFuY2Ugb2YgdGhlIFNvdXJjZU1hcEdlbmVyYXRvciByZXByZXNlbnRzIGEgc291cmNlIG1hcCB3aGljaCBpc1xuICogYmVpbmcgYnVpbHQgaW5jcmVtZW50YWxseS4gWW91IG1heSBwYXNzIGFuIG9iamVjdCB3aXRoIHRoZSBmb2xsb3dpbmdcbiAqIHByb3BlcnRpZXM6XG4gKlxuICogICAtIGZpbGU6IFRoZSBmaWxlbmFtZSBvZiB0aGUgZ2VuZXJhdGVkIHNvdXJjZS5cbiAqICAgLSBzb3VyY2VSb290OiBBIHJvb3QgZm9yIGFsbCByZWxhdGl2ZSBVUkxzIGluIHRoaXMgc291cmNlIG1hcC5cbiAqL1xuZnVuY3Rpb24gU291cmNlTWFwR2VuZXJhdG9yKGFBcmdzKSB7XG4gIGlmICghYUFyZ3MpIHtcbiAgICBhQXJncyA9IHt9O1xuICB9XG4gIHRoaXMuX2ZpbGUgPSB1dGlsLmdldEFyZyhhQXJncywgJ2ZpbGUnLCBudWxsKTtcbiAgdGhpcy5fc291cmNlUm9vdCA9IHV0aWwuZ2V0QXJnKGFBcmdzLCAnc291cmNlUm9vdCcsIG51bGwpO1xuICB0aGlzLl9za2lwVmFsaWRhdGlvbiA9IHV0aWwuZ2V0QXJnKGFBcmdzLCAnc2tpcFZhbGlkYXRpb24nLCBmYWxzZSk7XG4gIHRoaXMuX2lnbm9yZUludmFsaWRNYXBwaW5nID0gdXRpbC5nZXRBcmcoYUFyZ3MsICdpZ25vcmVJbnZhbGlkTWFwcGluZycsIGZhbHNlKTtcbiAgdGhpcy5fc291cmNlcyA9IG5ldyBBcnJheVNldCgpO1xuICB0aGlzLl9uYW1lcyA9IG5ldyBBcnJheVNldCgpO1xuICB0aGlzLl9tYXBwaW5ncyA9IG5ldyBNYXBwaW5nTGlzdCgpO1xuICB0aGlzLl9zb3VyY2VzQ29udGVudHMgPSBudWxsO1xufVxuXG5Tb3VyY2VNYXBHZW5lcmF0b3IucHJvdG90eXBlLl92ZXJzaW9uID0gMztcblxuLyoqXG4gKiBDcmVhdGVzIGEgbmV3IFNvdXJjZU1hcEdlbmVyYXRvciBiYXNlZCBvbiBhIFNvdXJjZU1hcENvbnN1bWVyXG4gKlxuICogQHBhcmFtIGFTb3VyY2VNYXBDb25zdW1lciBUaGUgU291cmNlTWFwLlxuICovXG5Tb3VyY2VNYXBHZW5lcmF0b3IuZnJvbVNvdXJjZU1hcCA9XG4gIGZ1bmN0aW9uIFNvdXJjZU1hcEdlbmVyYXRvcl9mcm9tU291cmNlTWFwKGFTb3VyY2VNYXBDb25zdW1lciwgZ2VuZXJhdG9yT3BzKSB7XG4gICAgdmFyIHNvdXJjZVJvb3QgPSBhU291cmNlTWFwQ29uc3VtZXIuc291cmNlUm9vdDtcbiAgICB2YXIgZ2VuZXJhdG9yID0gbmV3IFNvdXJjZU1hcEdlbmVyYXRvcihPYmplY3QuYXNzaWduKGdlbmVyYXRvck9wcyB8fCB7fSwge1xuICAgICAgZmlsZTogYVNvdXJjZU1hcENvbnN1bWVyLmZpbGUsXG4gICAgICBzb3VyY2VSb290OiBzb3VyY2VSb290XG4gICAgfSkpO1xuICAgIGFTb3VyY2VNYXBDb25zdW1lci5lYWNoTWFwcGluZyhmdW5jdGlvbiAobWFwcGluZykge1xuICAgICAgdmFyIG5ld01hcHBpbmcgPSB7XG4gICAgICAgIGdlbmVyYXRlZDoge1xuICAgICAgICAgIGxpbmU6IG1hcHBpbmcuZ2VuZXJhdGVkTGluZSxcbiAgICAgICAgICBjb2x1bW46IG1hcHBpbmcuZ2VuZXJhdGVkQ29sdW1uXG4gICAgICAgIH1cbiAgICAgIH07XG5cbiAgICAgIGlmIChtYXBwaW5nLnNvdXJjZSAhPSBudWxsKSB7XG4gICAgICAgIG5ld01hcHBpbmcuc291cmNlID0gbWFwcGluZy5zb3VyY2U7XG4gICAgICAgIGlmIChzb3VyY2VSb290ICE9IG51bGwpIHtcbiAgICAgICAgICBuZXdNYXBwaW5nLnNvdXJjZSA9IHV0aWwucmVsYXRpdmUoc291cmNlUm9vdCwgbmV3TWFwcGluZy5zb3VyY2UpO1xuICAgICAgICB9XG5cbiAgICAgICAgbmV3TWFwcGluZy5vcmlnaW5hbCA9IHtcbiAgICAgICAgICBsaW5lOiBtYXBwaW5nLm9yaWdpbmFsTGluZSxcbiAgICAgICAgICBjb2x1bW46IG1hcHBpbmcub3JpZ2luYWxDb2x1bW5cbiAgICAgICAgfTtcblxuICAgICAgICBpZiAobWFwcGluZy5uYW1lICE9IG51bGwpIHtcbiAgICAgICAgICBuZXdNYXBwaW5nLm5hbWUgPSBtYXBwaW5nLm5hbWU7XG4gICAgICAgIH1cbiAgICAgIH1cblxuICAgICAgZ2VuZXJhdG9yLmFkZE1hcHBpbmcobmV3TWFwcGluZyk7XG4gICAgfSk7XG4gICAgYVNvdXJjZU1hcENvbnN1bWVyLnNvdXJjZXMuZm9yRWFjaChmdW5jdGlvbiAoc291cmNlRmlsZSkge1xuICAgICAgdmFyIHNvdXJjZVJlbGF0aXZlID0gc291cmNlRmlsZTtcbiAgICAgIGlmIChzb3VyY2VSb290ICE9PSBudWxsKSB7XG4gICAgICAgIHNvdXJjZVJlbGF0aXZlID0gdXRpbC5yZWxhdGl2ZShzb3VyY2VSb290LCBzb3VyY2VGaWxlKTtcbiAgICAgIH1cblxuICAgICAgaWYgKCFnZW5lcmF0b3IuX3NvdXJjZXMuaGFzKHNvdXJjZVJlbGF0aXZlKSkge1xuICAgICAgICBnZW5lcmF0b3IuX3NvdXJjZXMuYWRkKHNvdXJjZVJlbGF0aXZlKTtcbiAgICAgIH1cblxuICAgICAgdmFyIGNvbnRlbnQgPSBhU291cmNlTWFwQ29uc3VtZXIuc291cmNlQ29udGVudEZvcihzb3VyY2VGaWxlKTtcbiAgICAgIGlmIChjb250ZW50ICE9IG51bGwpIHtcbiAgICAgICAgZ2VuZXJhdG9yLnNldFNvdXJjZUNvbnRlbnQoc291cmNlRmlsZSwgY29udGVudCk7XG4gICAgICB9XG4gICAgfSk7XG4gICAgcmV0dXJuIGdlbmVyYXRvcjtcbiAgfTtcblxuLyoqXG4gKiBBZGQgYSBzaW5nbGUgbWFwcGluZyBmcm9tIG9yaWdpbmFsIHNvdXJjZSBsaW5lIGFuZCBjb2x1bW4gdG8gdGhlIGdlbmVyYXRlZFxuICogc291cmNlJ3MgbGluZSBhbmQgY29sdW1uIGZvciB0aGlzIHNvdXJjZSBtYXAgYmVpbmcgY3JlYXRlZC4gVGhlIG1hcHBpbmdcbiAqIG9iamVjdCBzaG91bGQgaGF2ZSB0aGUgZm9sbG93aW5nIHByb3BlcnRpZXM6XG4gKlxuICogICAtIGdlbmVyYXRlZDogQW4gb2JqZWN0IHdpdGggdGhlIGdlbmVyYXRlZCBsaW5lIGFuZCBjb2x1bW4gcG9zaXRpb25zLlxuICogICAtIG9yaWdpbmFsOiBBbiBvYmplY3Qgd2l0aCB0aGUgb3JpZ2luYWwgbGluZSBhbmQgY29sdW1uIHBvc2l0aW9ucy5cbiAqICAgLSBzb3VyY2U6IFRoZSBvcmlnaW5hbCBzb3VyY2UgZmlsZSAocmVsYXRpdmUgdG8gdGhlIHNvdXJjZVJvb3QpLlxuICogICAtIG5hbWU6IEFuIG9wdGlvbmFsIG9yaWdpbmFsIHRva2VuIG5hbWUgZm9yIHRoaXMgbWFwcGluZy5cbiAqL1xuU291cmNlTWFwR2VuZXJhdG9yLnByb3RvdHlwZS5hZGRNYXBwaW5nID1cbiAgZnVuY3Rpb24gU291cmNlTWFwR2VuZXJhdG9yX2FkZE1hcHBpbmcoYUFyZ3MpIHtcbiAgICB2YXIgZ2VuZXJhdGVkID0gdXRpbC5nZXRBcmcoYUFyZ3MsICdnZW5lcmF0ZWQnKTtcbiAgICB2YXIgb3JpZ2luYWwgPSB1dGlsLmdldEFyZyhhQXJncywgJ29yaWdpbmFsJywgbnVsbCk7XG4gICAgdmFyIHNvdXJjZSA9IHV0aWwuZ2V0QXJnKGFBcmdzLCAnc291cmNlJywgbnVsbCk7XG4gICAgdmFyIG5hbWUgPSB1dGlsLmdldEFyZyhhQXJncywgJ25hbWUnLCBudWxsKTtcblxuICAgIGlmICghdGhpcy5fc2tpcFZhbGlkYXRpb24pIHtcbiAgICAgIGlmICh0aGlzLl92YWxpZGF0ZU1hcHBpbmcoZ2VuZXJhdGVkLCBvcmlnaW5hbCwgc291cmNlLCBuYW1lKSA9PT0gZmFsc2UpIHtcbiAgICAgICAgcmV0dXJuO1xuICAgICAgfVxuICAgIH1cblxuICAgIGlmIChzb3VyY2UgIT0gbnVsbCkge1xuICAgICAgc291cmNlID0gU3RyaW5nKHNvdXJjZSk7XG4gICAgICBpZiAoIXRoaXMuX3NvdXJjZXMuaGFzKHNvdXJjZSkpIHtcbiAgICAgICAgdGhpcy5fc291cmNlcy5hZGQoc291cmNlKTtcbiAgICAgIH1cbiAgICB9XG5cbiAgICBpZiAobmFtZSAhPSBudWxsKSB7XG4gICAgICBuYW1lID0gU3RyaW5nKG5hbWUpO1xuICAgICAgaWYgKCF0aGlzLl9uYW1lcy5oYXMobmFtZSkpIHtcbiAgICAgICAgdGhpcy5fbmFtZXMuYWRkKG5hbWUpO1xuICAgICAgfVxuICAgIH1cblxuICAgIHRoaXMuX21hcHBpbmdzLmFkZCh7XG4gICAgICBnZW5lcmF0ZWRMaW5lOiBnZW5lcmF0ZWQubGluZSxcbiAgICAgIGdlbmVyYXRlZENvbHVtbjogZ2VuZXJhdGVkLmNvbHVtbixcbiAgICAgIG9yaWdpbmFsTGluZTogb3JpZ2luYWwgIT0gbnVsbCAmJiBvcmlnaW5hbC5saW5lLFxuICAgICAgb3JpZ2luYWxDb2x1bW46IG9yaWdpbmFsICE9IG51bGwgJiYgb3JpZ2luYWwuY29sdW1uLFxuICAgICAgc291cmNlOiBzb3VyY2UsXG4gICAgICBuYW1lOiBuYW1lXG4gICAgfSk7XG4gIH07XG5cbi8qKlxuICogU2V0IHRoZSBzb3VyY2UgY29udGVudCBmb3IgYSBzb3VyY2UgZmlsZS5cbiAqL1xuU291cmNlTWFwR2VuZXJhdG9yLnByb3RvdHlwZS5zZXRTb3VyY2VDb250ZW50ID1cbiAgZnVuY3Rpb24gU291cmNlTWFwR2VuZXJhdG9yX3NldFNvdXJjZUNvbnRlbnQoYVNvdXJjZUZpbGUsIGFTb3VyY2VDb250ZW50KSB7XG4gICAgdmFyIHNvdXJjZSA9IGFTb3VyY2VGaWxlO1xuICAgIGlmICh0aGlzLl9zb3VyY2VSb290ICE9IG51bGwpIHtcbiAgICAgIHNvdXJjZSA9IHV0aWwucmVsYXRpdmUodGhpcy5fc291cmNlUm9vdCwgc291cmNlKTtcbiAgICB9XG5cbiAgICBpZiAoYVNvdXJjZUNvbnRlbnQgIT0gbnVsbCkge1xuICAgICAgLy8gQWRkIHRoZSBzb3VyY2UgY29udGVudCB0byB0aGUgX3NvdXJjZXNDb250ZW50cyBtYXAuXG4gICAgICAvLyBDcmVhdGUgYSBuZXcgX3NvdXJjZXNDb250ZW50cyBtYXAgaWYgdGhlIHByb3BlcnR5IGlzIG51bGwuXG4gICAgICBpZiAoIXRoaXMuX3NvdXJjZXNDb250ZW50cykge1xuICAgICAgICB0aGlzLl9zb3VyY2VzQ29udGVudHMgPSBPYmplY3QuY3JlYXRlKG51bGwpO1xuICAgICAgfVxuICAgICAgdGhpcy5fc291cmNlc0NvbnRlbnRzW3V0aWwudG9TZXRTdHJpbmcoc291cmNlKV0gPSBhU291cmNlQ29udGVudDtcbiAgICB9IGVsc2UgaWYgKHRoaXMuX3NvdXJjZXNDb250ZW50cykge1xuICAgICAgLy8gUmVtb3ZlIHRoZSBzb3VyY2UgZmlsZSBmcm9tIHRoZSBfc291cmNlc0NvbnRlbnRzIG1hcC5cbiAgICAgIC8vIElmIHRoZSBfc291cmNlc0NvbnRlbnRzIG1hcCBpcyBlbXB0eSwgc2V0IHRoZSBwcm9wZXJ0eSB0byBudWxsLlxuICAgICAgZGVsZXRlIHRoaXMuX3NvdXJjZXNDb250ZW50c1t1dGlsLnRvU2V0U3RyaW5nKHNvdXJjZSldO1xuICAgICAgaWYgKE9iamVjdC5rZXlzKHRoaXMuX3NvdXJjZXNDb250ZW50cykubGVuZ3RoID09PSAwKSB7XG4gICAgICAgIHRoaXMuX3NvdXJjZXNDb250ZW50cyA9IG51bGw7XG4gICAgICB9XG4gICAgfVxuICB9O1xuXG4vKipcbiAqIEFwcGxpZXMgdGhlIG1hcHBpbmdzIG9mIGEgc3ViLXNvdXJjZS1tYXAgZm9yIGEgc3BlY2lmaWMgc291cmNlIGZpbGUgdG8gdGhlXG4gKiBzb3VyY2UgbWFwIGJlaW5nIGdlbmVyYXRlZC4gRWFjaCBtYXBwaW5nIHRvIHRoZSBzdXBwbGllZCBzb3VyY2UgZmlsZSBpc1xuICogcmV3cml0dGVuIHVzaW5nIHRoZSBzdXBwbGllZCBzb3VyY2UgbWFwLiBOb3RlOiBUaGUgcmVzb2x1dGlvbiBmb3IgdGhlXG4gKiByZXN1bHRpbmcgbWFwcGluZ3MgaXMgdGhlIG1pbmltaXVtIG9mIHRoaXMgbWFwIGFuZCB0aGUgc3VwcGxpZWQgbWFwLlxuICpcbiAqIEBwYXJhbSBhU291cmNlTWFwQ29uc3VtZXIgVGhlIHNvdXJjZSBtYXAgdG8gYmUgYXBwbGllZC5cbiAqIEBwYXJhbSBhU291cmNlRmlsZSBPcHRpb25hbC4gVGhlIGZpbGVuYW1lIG9mIHRoZSBzb3VyY2UgZmlsZS5cbiAqICAgICAgICBJZiBvbWl0dGVkLCBTb3VyY2VNYXBDb25zdW1lcidzIGZpbGUgcHJvcGVydHkgd2lsbCBiZSB1c2VkLlxuICogQHBhcmFtIGFTb3VyY2VNYXBQYXRoIE9wdGlvbmFsLiBUaGUgZGlybmFtZSBvZiB0aGUgcGF0aCB0byB0aGUgc291cmNlIG1hcFxuICogICAgICAgIHRvIGJlIGFwcGxpZWQuIElmIHJlbGF0aXZlLCBpdCBpcyByZWxhdGl2ZSB0byB0aGUgU291cmNlTWFwQ29uc3VtZXIuXG4gKiAgICAgICAgVGhpcyBwYXJhbWV0ZXIgaXMgbmVlZGVkIHdoZW4gdGhlIHR3byBzb3VyY2UgbWFwcyBhcmVuJ3QgaW4gdGhlIHNhbWVcbiAqICAgICAgICBkaXJlY3RvcnksIGFuZCB0aGUgc291cmNlIG1hcCB0byBiZSBhcHBsaWVkIGNvbnRhaW5zIHJlbGF0aXZlIHNvdXJjZVxuICogICAgICAgIHBhdGhzLiBJZiBzbywgdGhvc2UgcmVsYXRpdmUgc291cmNlIHBhdGhzIG5lZWQgdG8gYmUgcmV3cml0dGVuXG4gKiAgICAgICAgcmVsYXRpdmUgdG8gdGhlIFNvdXJjZU1hcEdlbmVyYXRvci5cbiAqL1xuU291cmNlTWFwR2VuZXJhdG9yLnByb3RvdHlwZS5hcHBseVNvdXJjZU1hcCA9XG4gIGZ1bmN0aW9uIFNvdXJjZU1hcEdlbmVyYXRvcl9hcHBseVNvdXJjZU1hcChhU291cmNlTWFwQ29uc3VtZXIsIGFTb3VyY2VGaWxlLCBhU291cmNlTWFwUGF0aCkge1xuICAgIHZhciBzb3VyY2VGaWxlID0gYVNvdXJjZUZpbGU7XG4gICAgLy8gSWYgYVNvdXJjZUZpbGUgaXMgb21pdHRlZCwgd2Ugd2lsbCB1c2UgdGhlIGZpbGUgcHJvcGVydHkgb2YgdGhlIFNvdXJjZU1hcFxuICAgIGlmIChhU291cmNlRmlsZSA9PSBudWxsKSB7XG4gICAgICBpZiAoYVNvdXJjZU1hcENvbnN1bWVyLmZpbGUgPT0gbnVsbCkge1xuICAgICAgICB0aHJvdyBuZXcgRXJyb3IoXG4gICAgICAgICAgJ1NvdXJjZU1hcEdlbmVyYXRvci5wcm90b3R5cGUuYXBwbHlTb3VyY2VNYXAgcmVxdWlyZXMgZWl0aGVyIGFuIGV4cGxpY2l0IHNvdXJjZSBmaWxlLCAnICtcbiAgICAgICAgICAnb3IgdGhlIHNvdXJjZSBtYXBcXCdzIFwiZmlsZVwiIHByb3BlcnR5LiBCb3RoIHdlcmUgb21pdHRlZC4nXG4gICAgICAgICk7XG4gICAgICB9XG4gICAgICBzb3VyY2VGaWxlID0gYVNvdXJjZU1hcENvbnN1bWVyLmZpbGU7XG4gICAgfVxuICAgIHZhciBzb3VyY2VSb290ID0gdGhpcy5fc291cmNlUm9vdDtcbiAgICAvLyBNYWtlIFwic291cmNlRmlsZVwiIHJlbGF0aXZlIGlmIGFuIGFic29sdXRlIFVybCBpcyBwYXNzZWQuXG4gICAgaWYgKHNvdXJjZVJvb3QgIT0gbnVsbCkge1xuICAgICAgc291cmNlRmlsZSA9IHV0aWwucmVsYXRpdmUoc291cmNlUm9vdCwgc291cmNlRmlsZSk7XG4gICAgfVxuICAgIC8vIEFwcGx5aW5nIHRoZSBTb3VyY2VNYXAgY2FuIGFkZCBhbmQgcmVtb3ZlIGl0ZW1zIGZyb20gdGhlIHNvdXJjZXMgYW5kXG4gICAgLy8gdGhlIG5hbWVzIGFycmF5LlxuICAgIHZhciBuZXdTb3VyY2VzID0gbmV3IEFycmF5U2V0KCk7XG4gICAgdmFyIG5ld05hbWVzID0gbmV3IEFycmF5U2V0KCk7XG5cbiAgICAvLyBGaW5kIG1hcHBpbmdzIGZvciB0aGUgXCJzb3VyY2VGaWxlXCJcbiAgICB0aGlzLl9tYXBwaW5ncy51bnNvcnRlZEZvckVhY2goZnVuY3Rpb24gKG1hcHBpbmcpIHtcbiAgICAgIGlmIChtYXBwaW5nLnNvdXJjZSA9PT0gc291cmNlRmlsZSAmJiBtYXBwaW5nLm9yaWdpbmFsTGluZSAhPSBudWxsKSB7XG4gICAgICAgIC8vIENoZWNrIGlmIGl0IGNhbiBiZSBtYXBwZWQgYnkgdGhlIHNvdXJjZSBtYXAsIHRoZW4gdXBkYXRlIHRoZSBtYXBwaW5nLlxuICAgICAgICB2YXIgb3JpZ2luYWwgPSBhU291cmNlTWFwQ29uc3VtZXIub3JpZ2luYWxQb3NpdGlvbkZvcih7XG4gICAgICAgICAgbGluZTogbWFwcGluZy5vcmlnaW5hbExpbmUsXG4gICAgICAgICAgY29sdW1uOiBtYXBwaW5nLm9yaWdpbmFsQ29sdW1uXG4gICAgICAgIH0pO1xuICAgICAgICBpZiAob3JpZ2luYWwuc291cmNlICE9IG51bGwpIHtcbiAgICAgICAgICAvLyBDb3B5IG1hcHBpbmdcbiAgICAgICAgICBtYXBwaW5nLnNvdXJjZSA9IG9yaWdpbmFsLnNvdXJjZTtcbiAgICAgICAgICBpZiAoYVNvdXJjZU1hcFBhdGggIT0gbnVsbCkge1xuICAgICAgICAgICAgbWFwcGluZy5zb3VyY2UgPSB1dGlsLmpvaW4oYVNvdXJjZU1hcFBhdGgsIG1hcHBpbmcuc291cmNlKVxuICAgICAgICAgIH1cbiAgICAgICAgICBpZiAoc291cmNlUm9vdCAhPSBudWxsKSB7XG4gICAgICAgICAgICBtYXBwaW5nLnNvdXJjZSA9IHV0aWwucmVsYXRpdmUoc291cmNlUm9vdCwgbWFwcGluZy5zb3VyY2UpO1xuICAgICAgICAgIH1cbiAgICAgICAgICBtYXBwaW5nLm9yaWdpbmFsTGluZSA9IG9yaWdpbmFsLmxpbmU7XG4gICAgICAgICAgbWFwcGluZy5vcmlnaW5hbENvbHVtbiA9IG9yaWdpbmFsLmNvbHVtbjtcbiAgICAgICAgICBpZiAob3JpZ2luYWwubmFtZSAhPSBudWxsKSB7XG4gICAgICAgICAgICBtYXBwaW5nLm5hbWUgPSBvcmlnaW5hbC5uYW1lO1xuICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgfVxuXG4gICAgICB2YXIgc291cmNlID0gbWFwcGluZy5zb3VyY2U7XG4gICAgICBpZiAoc291cmNlICE9IG51bGwgJiYgIW5ld1NvdXJjZXMuaGFzKHNvdXJjZSkpIHtcbiAgICAgICAgbmV3U291cmNlcy5hZGQoc291cmNlKTtcbiAgICAgIH1cblxuICAgICAgdmFyIG5hbWUgPSBtYXBwaW5nLm5hbWU7XG4gICAgICBpZiAobmFtZSAhPSBudWxsICYmICFuZXdOYW1lcy5oYXMobmFtZSkpIHtcbiAgICAgICAgbmV3TmFtZXMuYWRkKG5hbWUpO1xuICAgICAgfVxuXG4gICAgfSwgdGhpcyk7XG4gICAgdGhpcy5fc291cmNlcyA9IG5ld1NvdXJjZXM7XG4gICAgdGhpcy5fbmFtZXMgPSBuZXdOYW1lcztcblxuICAgIC8vIENvcHkgc291cmNlc0NvbnRlbnRzIG9mIGFwcGxpZWQgbWFwLlxuICAgIGFTb3VyY2VNYXBDb25zdW1lci5zb3VyY2VzLmZvckVhY2goZnVuY3Rpb24gKHNvdXJjZUZpbGUpIHtcbiAgICAgIHZhciBjb250ZW50ID0gYVNvdXJjZU1hcENvbnN1bWVyLnNvdXJjZUNvbnRlbnRGb3Ioc291cmNlRmlsZSk7XG4gICAgICBpZiAoY29udGVudCAhPSBudWxsKSB7XG4gICAgICAgIGlmIChhU291cmNlTWFwUGF0aCAhPSBudWxsKSB7XG4gICAgICAgICAgc291cmNlRmlsZSA9IHV0aWwuam9pbihhU291cmNlTWFwUGF0aCwgc291cmNlRmlsZSk7XG4gICAgICAgIH1cbiAgICAgICAgaWYgKHNvdXJjZVJvb3QgIT0gbnVsbCkge1xuICAgICAgICAgIHNvdXJjZUZpbGUgPSB1dGlsLnJlbGF0aXZlKHNvdXJjZVJvb3QsIHNvdXJjZUZpbGUpO1xuICAgICAgICB9XG4gICAgICAgIHRoaXMuc2V0U291cmNlQ29udGVudChzb3VyY2VGaWxlLCBjb250ZW50KTtcbiAgICAgIH1cbiAgICB9LCB0aGlzKTtcbiAgfTtcblxuLyoqXG4gKiBBIG1hcHBpbmcgY2FuIGhhdmUgb25lIG9mIHRoZSB0aHJlZSBsZXZlbHMgb2YgZGF0YTpcbiAqXG4gKiAgIDEuIEp1c3QgdGhlIGdlbmVyYXRlZCBwb3NpdGlvbi5cbiAqICAgMi4gVGhlIEdlbmVyYXRlZCBwb3NpdGlvbiwgb3JpZ2luYWwgcG9zaXRpb24sIGFuZCBvcmlnaW5hbCBzb3VyY2UuXG4gKiAgIDMuIEdlbmVyYXRlZCBhbmQgb3JpZ2luYWwgcG9zaXRpb24sIG9yaWdpbmFsIHNvdXJjZSwgYXMgd2VsbCBhcyBhIG5hbWVcbiAqICAgICAgdG9rZW4uXG4gKlxuICogVG8gbWFpbnRhaW4gY29uc2lzdGVuY3ksIHdlIHZhbGlkYXRlIHRoYXQgYW55IG5ldyBtYXBwaW5nIGJlaW5nIGFkZGVkIGZhbGxzXG4gKiBpbiB0byBvbmUgb2YgdGhlc2UgY2F0ZWdvcmllcy5cbiAqL1xuU291cmNlTWFwR2VuZXJhdG9yLnByb3RvdHlwZS5fdmFsaWRhdGVNYXBwaW5nID1cbiAgZnVuY3Rpb24gU291cmNlTWFwR2VuZXJhdG9yX3ZhbGlkYXRlTWFwcGluZyhhR2VuZXJhdGVkLCBhT3JpZ2luYWwsIGFTb3VyY2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYU5hbWUpIHtcbiAgICAvLyBXaGVuIGFPcmlnaW5hbCBpcyB0cnV0aHkgYnV0IGhhcyBlbXB0eSB2YWx1ZXMgZm9yIC5saW5lIGFuZCAuY29sdW1uLFxuICAgIC8vIGl0IGlzIG1vc3QgbGlrZWx5IGEgcHJvZ3JhbW1lciBlcnJvci4gSW4gdGhpcyBjYXNlIHdlIHRocm93IGEgdmVyeVxuICAgIC8vIHNwZWNpZmljIGVycm9yIG1lc3NhZ2UgdG8gdHJ5IHRvIGd1aWRlIHRoZW0gdGhlIHJpZ2h0IHdheS5cbiAgICAvLyBGb3IgZXhhbXBsZTogaHR0cHM6Ly9naXRodWIuY29tL1BvbHltZXIvcG9seW1lci1idW5kbGVyL3B1bGwvNTE5XG4gICAgaWYgKGFPcmlnaW5hbCAmJiB0eXBlb2YgYU9yaWdpbmFsLmxpbmUgIT09ICdudW1iZXInICYmIHR5cGVvZiBhT3JpZ2luYWwuY29sdW1uICE9PSAnbnVtYmVyJykge1xuICAgICAgdmFyIG1lc3NhZ2UgPSAnb3JpZ2luYWwubGluZSBhbmQgb3JpZ2luYWwuY29sdW1uIGFyZSBub3QgbnVtYmVycyAtLSB5b3UgcHJvYmFibHkgbWVhbnQgdG8gb21pdCAnICtcbiAgICAgICd0aGUgb3JpZ2luYWwgbWFwcGluZyBlbnRpcmVseSBhbmQgb25seSBtYXAgdGhlIGdlbmVyYXRlZCBwb3NpdGlvbi4gSWYgc28sIHBhc3MgJyArXG4gICAgICAnbnVsbCBmb3IgdGhlIG9yaWdpbmFsIG1hcHBpbmcgaW5zdGVhZCBvZiBhbiBvYmplY3Qgd2l0aCBlbXB0eSBvciBudWxsIHZhbHVlcy4nXG5cbiAgICAgIGlmICh0aGlzLl9pZ25vcmVJbnZhbGlkTWFwcGluZykge1xuICAgICAgICBpZiAodHlwZW9mIGNvbnNvbGUgIT09ICd1bmRlZmluZWQnICYmIGNvbnNvbGUud2Fybikge1xuICAgICAgICAgIGNvbnNvbGUud2FybihtZXNzYWdlKTtcbiAgICAgICAgfVxuICAgICAgICByZXR1cm4gZmFsc2U7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICB0aHJvdyBuZXcgRXJyb3IobWVzc2FnZSk7XG4gICAgICB9XG4gICAgfVxuXG4gICAgaWYgKGFHZW5lcmF0ZWQgJiYgJ2xpbmUnIGluIGFHZW5lcmF0ZWQgJiYgJ2NvbHVtbicgaW4gYUdlbmVyYXRlZFxuICAgICAgICAmJiBhR2VuZXJhdGVkLmxpbmUgPiAwICYmIGFHZW5lcmF0ZWQuY29sdW1uID49IDBcbiAgICAgICAgJiYgIWFPcmlnaW5hbCAmJiAhYVNvdXJjZSAmJiAhYU5hbWUpIHtcbiAgICAgIC8vIENhc2UgMS5cbiAgICAgIHJldHVybjtcbiAgICB9XG4gICAgZWxzZSBpZiAoYUdlbmVyYXRlZCAmJiAnbGluZScgaW4gYUdlbmVyYXRlZCAmJiAnY29sdW1uJyBpbiBhR2VuZXJhdGVkXG4gICAgICAgICAgICAgJiYgYU9yaWdpbmFsICYmICdsaW5lJyBpbiBhT3JpZ2luYWwgJiYgJ2NvbHVtbicgaW4gYU9yaWdpbmFsXG4gICAgICAgICAgICAgJiYgYUdlbmVyYXRlZC5saW5lID4gMCAmJiBhR2VuZXJhdGVkLmNvbHVtbiA+PSAwXG4gICAgICAgICAgICAgJiYgYU9yaWdpbmFsLmxpbmUgPiAwICYmIGFPcmlnaW5hbC5jb2x1bW4gPj0gMFxuICAgICAgICAgICAgICYmIGFTb3VyY2UpIHtcbiAgICAgIC8vIENhc2VzIDIgYW5kIDMuXG4gICAgICByZXR1cm47XG4gICAgfVxuICAgIGVsc2Uge1xuICAgICAgdmFyIG1lc3NhZ2UgPSAnSW52YWxpZCBtYXBwaW5nOiAnICsgSlNPTi5zdHJpbmdpZnkoe1xuICAgICAgICBnZW5lcmF0ZWQ6IGFHZW5lcmF0ZWQsXG4gICAgICAgIHNvdXJjZTogYVNvdXJjZSxcbiAgICAgICAgb3JpZ2luYWw6IGFPcmlnaW5hbCxcbiAgICAgICAgbmFtZTogYU5hbWVcbiAgICAgIH0pO1xuXG4gICAgICBpZiAodGhpcy5faWdub3JlSW52YWxpZE1hcHBpbmcpIHtcbiAgICAgICAgaWYgKHR5cGVvZiBjb25zb2xlICE9PSAndW5kZWZpbmVkJyAmJiBjb25zb2xlLndhcm4pIHtcbiAgICAgICAgICBjb25zb2xlLndhcm4obWVzc2FnZSk7XG4gICAgICAgIH1cbiAgICAgICAgcmV0dXJuIGZhbHNlO1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgdGhyb3cgbmV3IEVycm9yKG1lc3NhZ2UpXG4gICAgICB9XG4gICAgfVxuICB9O1xuXG4vKipcbiAqIFNlcmlhbGl6ZSB0aGUgYWNjdW11bGF0ZWQgbWFwcGluZ3MgaW4gdG8gdGhlIHN0cmVhbSBvZiBiYXNlIDY0IFZMUXNcbiAqIHNwZWNpZmllZCBieSB0aGUgc291cmNlIG1hcCBmb3JtYXQuXG4gKi9cblNvdXJjZU1hcEdlbmVyYXRvci5wcm90b3R5cGUuX3NlcmlhbGl6ZU1hcHBpbmdzID1cbiAgZnVuY3Rpb24gU291cmNlTWFwR2VuZXJhdG9yX3NlcmlhbGl6ZU1hcHBpbmdzKCkge1xuICAgIHZhciBwcmV2aW91c0dlbmVyYXRlZENvbHVtbiA9IDA7XG4gICAgdmFyIHByZXZpb3VzR2VuZXJhdGVkTGluZSA9IDE7XG4gICAgdmFyIHByZXZpb3VzT3JpZ2luYWxDb2x1bW4gPSAwO1xuICAgIHZhciBwcmV2aW91c09yaWdpbmFsTGluZSA9IDA7XG4gICAgdmFyIHByZXZpb3VzTmFtZSA9IDA7XG4gICAgdmFyIHByZXZpb3VzU291cmNlID0gMDtcbiAgICB2YXIgcmVzdWx0ID0gJyc7XG4gICAgdmFyIG5leHQ7XG4gICAgdmFyIG1hcHBpbmc7XG4gICAgdmFyIG5hbWVJZHg7XG4gICAgdmFyIHNvdXJjZUlkeDtcblxuICAgIHZhciBtYXBwaW5ncyA9IHRoaXMuX21hcHBpbmdzLnRvQXJyYXkoKTtcbiAgICBmb3IgKHZhciBpID0gMCwgbGVuID0gbWFwcGluZ3MubGVuZ3RoOyBpIDwgbGVuOyBpKyspIHtcbiAgICAgIG1hcHBpbmcgPSBtYXBwaW5nc1tpXTtcbiAgICAgIG5leHQgPSAnJ1xuXG4gICAgICBpZiAobWFwcGluZy5nZW5lcmF0ZWRMaW5lICE9PSBwcmV2aW91c0dlbmVyYXRlZExpbmUpIHtcbiAgICAgICAgcHJldmlvdXNHZW5lcmF0ZWRDb2x1bW4gPSAwO1xuICAgICAgICB3aGlsZSAobWFwcGluZy5nZW5lcmF0ZWRMaW5lICE9PSBwcmV2aW91c0dlbmVyYXRlZExpbmUpIHtcbiAgICAgICAgICBuZXh0ICs9ICc7JztcbiAgICAgICAgICBwcmV2aW91c0dlbmVyYXRlZExpbmUrKztcbiAgICAgICAgfVxuICAgICAgfVxuICAgICAgZWxzZSB7XG4gICAgICAgIGlmIChpID4gMCkge1xuICAgICAgICAgIGlmICghdXRpbC5jb21wYXJlQnlHZW5lcmF0ZWRQb3NpdGlvbnNJbmZsYXRlZChtYXBwaW5nLCBtYXBwaW5nc1tpIC0gMV0pKSB7XG4gICAgICAgICAgICBjb250aW51ZTtcbiAgICAgICAgICB9XG4gICAgICAgICAgbmV4dCArPSAnLCc7XG4gICAgICAgIH1cbiAgICAgIH1cblxuICAgICAgbmV4dCArPSBiYXNlNjRWTFEuZW5jb2RlKG1hcHBpbmcuZ2VuZXJhdGVkQ29sdW1uXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAtIHByZXZpb3VzR2VuZXJhdGVkQ29sdW1uKTtcbiAgICAgIHByZXZpb3VzR2VuZXJhdGVkQ29sdW1uID0gbWFwcGluZy5nZW5lcmF0ZWRDb2x1bW47XG5cbiAgICAgIGlmIChtYXBwaW5nLnNvdXJjZSAhPSBudWxsKSB7XG4gICAgICAgIHNvdXJjZUlkeCA9IHRoaXMuX3NvdXJjZXMuaW5kZXhPZihtYXBwaW5nLnNvdXJjZSk7XG4gICAgICAgIG5leHQgKz0gYmFzZTY0VkxRLmVuY29kZShzb3VyY2VJZHggLSBwcmV2aW91c1NvdXJjZSk7XG4gICAgICAgIHByZXZpb3VzU291cmNlID0gc291cmNlSWR4O1xuXG4gICAgICAgIC8vIGxpbmVzIGFyZSBzdG9yZWQgMC1iYXNlZCBpbiBTb3VyY2VNYXAgc3BlYyB2ZXJzaW9uIDNcbiAgICAgICAgbmV4dCArPSBiYXNlNjRWTFEuZW5jb2RlKG1hcHBpbmcub3JpZ2luYWxMaW5lIC0gMVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAtIHByZXZpb3VzT3JpZ2luYWxMaW5lKTtcbiAgICAgICAgcHJldmlvdXNPcmlnaW5hbExpbmUgPSBtYXBwaW5nLm9yaWdpbmFsTGluZSAtIDE7XG5cbiAgICAgICAgbmV4dCArPSBiYXNlNjRWTFEuZW5jb2RlKG1hcHBpbmcub3JpZ2luYWxDb2x1bW5cbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgLSBwcmV2aW91c09yaWdpbmFsQ29sdW1uKTtcbiAgICAgICAgcHJldmlvdXNPcmlnaW5hbENvbHVtbiA9IG1hcHBpbmcub3JpZ2luYWxDb2x1bW47XG5cbiAgICAgICAgaWYgKG1hcHBpbmcubmFtZSAhPSBudWxsKSB7XG4gICAgICAgICAgbmFtZUlkeCA9IHRoaXMuX25hbWVzLmluZGV4T2YobWFwcGluZy5uYW1lKTtcbiAgICAgICAgICBuZXh0ICs9IGJhc2U2NFZMUS5lbmNvZGUobmFtZUlkeCAtIHByZXZpb3VzTmFtZSk7XG4gICAgICAgICAgcHJldmlvdXNOYW1lID0gbmFtZUlkeDtcbiAgICAgICAgfVxuICAgICAgfVxuXG4gICAgICByZXN1bHQgKz0gbmV4dDtcbiAgICB9XG5cbiAgICByZXR1cm4gcmVzdWx0O1xuICB9O1xuXG5Tb3VyY2VNYXBHZW5lcmF0b3IucHJvdG90eXBlLl9nZW5lcmF0ZVNvdXJjZXNDb250ZW50ID1cbiAgZnVuY3Rpb24gU291cmNlTWFwR2VuZXJhdG9yX2dlbmVyYXRlU291cmNlc0NvbnRlbnQoYVNvdXJjZXMsIGFTb3VyY2VSb290KSB7XG4gICAgcmV0dXJuIGFTb3VyY2VzLm1hcChmdW5jdGlvbiAoc291cmNlKSB7XG4gICAgICBpZiAoIXRoaXMuX3NvdXJjZXNDb250ZW50cykge1xuICAgICAgICByZXR1cm4gbnVsbDtcbiAgICAgIH1cbiAgICAgIGlmIChhU291cmNlUm9vdCAhPSBudWxsKSB7XG4gICAgICAgIHNvdXJjZSA9IHV0aWwucmVsYXRpdmUoYVNvdXJjZVJvb3QsIHNvdXJjZSk7XG4gICAgICB9XG4gICAgICB2YXIga2V5ID0gdXRpbC50b1NldFN0cmluZyhzb3VyY2UpO1xuICAgICAgcmV0dXJuIE9iamVjdC5wcm90b3R5cGUuaGFzT3duUHJvcGVydHkuY2FsbCh0aGlzLl9zb3VyY2VzQ29udGVudHMsIGtleSlcbiAgICAgICAgPyB0aGlzLl9zb3VyY2VzQ29udGVudHNba2V5XVxuICAgICAgICA6IG51bGw7XG4gICAgfSwgdGhpcyk7XG4gIH07XG5cbi8qKlxuICogRXh0ZXJuYWxpemUgdGhlIHNvdXJjZSBtYXAuXG4gKi9cblNvdXJjZU1hcEdlbmVyYXRvci5wcm90b3R5cGUudG9KU09OID1cbiAgZnVuY3Rpb24gU291cmNlTWFwR2VuZXJhdG9yX3RvSlNPTigpIHtcbiAgICB2YXIgbWFwID0ge1xuICAgICAgdmVyc2lvbjogdGhpcy5fdmVyc2lvbixcbiAgICAgIHNvdXJjZXM6IHRoaXMuX3NvdXJjZXMudG9BcnJheSgpLFxuICAgICAgbmFtZXM6IHRoaXMuX25hbWVzLnRvQXJyYXkoKSxcbiAgICAgIG1hcHBpbmdzOiB0aGlzLl9zZXJpYWxpemVNYXBwaW5ncygpXG4gICAgfTtcbiAgICBpZiAodGhpcy5fZmlsZSAhPSBudWxsKSB7XG4gICAgICBtYXAuZmlsZSA9IHRoaXMuX2ZpbGU7XG4gICAgfVxuICAgIGlmICh0aGlzLl9zb3VyY2VSb290ICE9IG51bGwpIHtcbiAgICAgIG1hcC5zb3VyY2VSb290ID0gdGhpcy5fc291cmNlUm9vdDtcbiAgICB9XG4gICAgaWYgKHRoaXMuX3NvdXJjZXNDb250ZW50cykge1xuICAgICAgbWFwLnNvdXJjZXNDb250ZW50ID0gdGhpcy5fZ2VuZXJhdGVTb3VyY2VzQ29udGVudChtYXAuc291cmNlcywgbWFwLnNvdXJjZVJvb3QpO1xuICAgIH1cblxuICAgIHJldHVybiBtYXA7XG4gIH07XG5cbi8qKlxuICogUmVuZGVyIHRoZSBzb3VyY2UgbWFwIGJlaW5nIGdlbmVyYXRlZCB0byBhIHN0cmluZy5cbiAqL1xuU291cmNlTWFwR2VuZXJhdG9yLnByb3RvdHlwZS50b1N0cmluZyA9XG4gIGZ1bmN0aW9uIFNvdXJjZU1hcEdlbmVyYXRvcl90b1N0cmluZygpIHtcbiAgICByZXR1cm4gSlNPTi5zdHJpbmdpZnkodGhpcy50b0pTT04oKSk7XG4gIH07XG5cbmV4cG9ydHMuU291cmNlTWFwR2VuZXJhdG9yID0gU291cmNlTWFwR2VuZXJhdG9yO1xuIiwgIi8qIC0qLSBNb2RlOiBqczsganMtaW5kZW50LWxldmVsOiAyOyAtKi0gKi9cbi8qXG4gKiBDb3B5cmlnaHQgMjAxMSBNb3ppbGxhIEZvdW5kYXRpb24gYW5kIGNvbnRyaWJ1dG9yc1xuICogTGljZW5zZWQgdW5kZXIgdGhlIE5ldyBCU0QgbGljZW5zZS4gU2VlIExJQ0VOU0Ugb3I6XG4gKiBodHRwOi8vb3BlbnNvdXJjZS5vcmcvbGljZW5zZXMvQlNELTMtQ2xhdXNlXG4gKi9cblxuZXhwb3J0cy5HUkVBVEVTVF9MT1dFUl9CT1VORCA9IDE7XG5leHBvcnRzLkxFQVNUX1VQUEVSX0JPVU5EID0gMjtcblxuLyoqXG4gKiBSZWN1cnNpdmUgaW1wbGVtZW50YXRpb24gb2YgYmluYXJ5IHNlYXJjaC5cbiAqXG4gKiBAcGFyYW0gYUxvdyBJbmRpY2VzIGhlcmUgYW5kIGxvd2VyIGRvIG5vdCBjb250YWluIHRoZSBuZWVkbGUuXG4gKiBAcGFyYW0gYUhpZ2ggSW5kaWNlcyBoZXJlIGFuZCBoaWdoZXIgZG8gbm90IGNvbnRhaW4gdGhlIG5lZWRsZS5cbiAqIEBwYXJhbSBhTmVlZGxlIFRoZSBlbGVtZW50IGJlaW5nIHNlYXJjaGVkIGZvci5cbiAqIEBwYXJhbSBhSGF5c3RhY2sgVGhlIG5vbi1lbXB0eSBhcnJheSBiZWluZyBzZWFyY2hlZC5cbiAqIEBwYXJhbSBhQ29tcGFyZSBGdW5jdGlvbiB3aGljaCB0YWtlcyB0d28gZWxlbWVudHMgYW5kIHJldHVybnMgLTEsIDAsIG9yIDEuXG4gKiBAcGFyYW0gYUJpYXMgRWl0aGVyICdiaW5hcnlTZWFyY2guR1JFQVRFU1RfTE9XRVJfQk9VTkQnIG9yXG4gKiAgICAgJ2JpbmFyeVNlYXJjaC5MRUFTVF9VUFBFUl9CT1VORCcuIFNwZWNpZmllcyB3aGV0aGVyIHRvIHJldHVybiB0aGVcbiAqICAgICBjbG9zZXN0IGVsZW1lbnQgdGhhdCBpcyBzbWFsbGVyIHRoYW4gb3IgZ3JlYXRlciB0aGFuIHRoZSBvbmUgd2UgYXJlXG4gKiAgICAgc2VhcmNoaW5nIGZvciwgcmVzcGVjdGl2ZWx5LCBpZiB0aGUgZXhhY3QgZWxlbWVudCBjYW5ub3QgYmUgZm91bmQuXG4gKi9cbmZ1bmN0aW9uIHJlY3Vyc2l2ZVNlYXJjaChhTG93LCBhSGlnaCwgYU5lZWRsZSwgYUhheXN0YWNrLCBhQ29tcGFyZSwgYUJpYXMpIHtcbiAgLy8gVGhpcyBmdW5jdGlvbiB0ZXJtaW5hdGVzIHdoZW4gb25lIG9mIHRoZSBmb2xsb3dpbmcgaXMgdHJ1ZTpcbiAgLy9cbiAgLy8gICAxLiBXZSBmaW5kIHRoZSBleGFjdCBlbGVtZW50IHdlIGFyZSBsb29raW5nIGZvci5cbiAgLy9cbiAgLy8gICAyLiBXZSBkaWQgbm90IGZpbmQgdGhlIGV4YWN0IGVsZW1lbnQsIGJ1dCB3ZSBjYW4gcmV0dXJuIHRoZSBpbmRleCBvZlxuICAvLyAgICAgIHRoZSBuZXh0LWNsb3Nlc3QgZWxlbWVudC5cbiAgLy9cbiAgLy8gICAzLiBXZSBkaWQgbm90IGZpbmQgdGhlIGV4YWN0IGVsZW1lbnQsIGFuZCB0aGVyZSBpcyBubyBuZXh0LWNsb3Nlc3RcbiAgLy8gICAgICBlbGVtZW50IHRoYW4gdGhlIG9uZSB3ZSBhcmUgc2VhcmNoaW5nIGZvciwgc28gd2UgcmV0dXJuIC0xLlxuICB2YXIgbWlkID0gTWF0aC5mbG9vcigoYUhpZ2ggLSBhTG93KSAvIDIpICsgYUxvdztcbiAgdmFyIGNtcCA9IGFDb21wYXJlKGFOZWVkbGUsIGFIYXlzdGFja1ttaWRdLCB0cnVlKTtcbiAgaWYgKGNtcCA9PT0gMCkge1xuICAgIC8vIEZvdW5kIHRoZSBlbGVtZW50IHdlIGFyZSBsb29raW5nIGZvci5cbiAgICByZXR1cm4gbWlkO1xuICB9XG4gIGVsc2UgaWYgKGNtcCA+IDApIHtcbiAgICAvLyBPdXIgbmVlZGxlIGlzIGdyZWF0ZXIgdGhhbiBhSGF5c3RhY2tbbWlkXS5cbiAgICBpZiAoYUhpZ2ggLSBtaWQgPiAxKSB7XG4gICAgICAvLyBUaGUgZWxlbWVudCBpcyBpbiB0aGUgdXBwZXIgaGFsZi5cbiAgICAgIHJldHVybiByZWN1cnNpdmVTZWFyY2gobWlkLCBhSGlnaCwgYU5lZWRsZSwgYUhheXN0YWNrLCBhQ29tcGFyZSwgYUJpYXMpO1xuICAgIH1cblxuICAgIC8vIFRoZSBleGFjdCBuZWVkbGUgZWxlbWVudCB3YXMgbm90IGZvdW5kIGluIHRoaXMgaGF5c3RhY2suIERldGVybWluZSBpZlxuICAgIC8vIHdlIGFyZSBpbiB0ZXJtaW5hdGlvbiBjYXNlICgzKSBvciAoMikgYW5kIHJldHVybiB0aGUgYXBwcm9wcmlhdGUgdGhpbmcuXG4gICAgaWYgKGFCaWFzID09IGV4cG9ydHMuTEVBU1RfVVBQRVJfQk9VTkQpIHtcbiAgICAgIHJldHVybiBhSGlnaCA8IGFIYXlzdGFjay5sZW5ndGggPyBhSGlnaCA6IC0xO1xuICAgIH0gZWxzZSB7XG4gICAgICByZXR1cm4gbWlkO1xuICAgIH1cbiAgfVxuICBlbHNlIHtcbiAgICAvLyBPdXIgbmVlZGxlIGlzIGxlc3MgdGhhbiBhSGF5c3RhY2tbbWlkXS5cbiAgICBpZiAobWlkIC0gYUxvdyA+IDEpIHtcbiAgICAgIC8vIFRoZSBlbGVtZW50IGlzIGluIHRoZSBsb3dlciBoYWxmLlxuICAgICAgcmV0dXJuIHJlY3Vyc2l2ZVNlYXJjaChhTG93LCBtaWQsIGFOZWVkbGUsIGFIYXlzdGFjaywgYUNvbXBhcmUsIGFCaWFzKTtcbiAgICB9XG5cbiAgICAvLyB3ZSBhcmUgaW4gdGVybWluYXRpb24gY2FzZSAoMykgb3IgKDIpIGFuZCByZXR1cm4gdGhlIGFwcHJvcHJpYXRlIHRoaW5nLlxuICAgIGlmIChhQmlhcyA9PSBleHBvcnRzLkxFQVNUX1VQUEVSX0JPVU5EKSB7XG4gICAgICByZXR1cm4gbWlkO1xuICAgIH0gZWxzZSB7XG4gICAgICByZXR1cm4gYUxvdyA8IDAgPyAtMSA6IGFMb3c7XG4gICAgfVxuICB9XG59XG5cbi8qKlxuICogVGhpcyBpcyBhbiBpbXBsZW1lbnRhdGlvbiBvZiBiaW5hcnkgc2VhcmNoIHdoaWNoIHdpbGwgYWx3YXlzIHRyeSBhbmQgcmV0dXJuXG4gKiB0aGUgaW5kZXggb2YgdGhlIGNsb3Nlc3QgZWxlbWVudCBpZiB0aGVyZSBpcyBubyBleGFjdCBoaXQuIFRoaXMgaXMgYmVjYXVzZVxuICogbWFwcGluZ3MgYmV0d2VlbiBvcmlnaW5hbCBhbmQgZ2VuZXJhdGVkIGxpbmUvY29sIHBhaXJzIGFyZSBzaW5nbGUgcG9pbnRzLFxuICogYW5kIHRoZXJlIGlzIGFuIGltcGxpY2l0IHJlZ2lvbiBiZXR3ZWVuIGVhY2ggb2YgdGhlbSwgc28gYSBtaXNzIGp1c3QgbWVhbnNcbiAqIHRoYXQgeW91IGFyZW4ndCBvbiB0aGUgdmVyeSBzdGFydCBvZiBhIHJlZ2lvbi5cbiAqXG4gKiBAcGFyYW0gYU5lZWRsZSBUaGUgZWxlbWVudCB5b3UgYXJlIGxvb2tpbmcgZm9yLlxuICogQHBhcmFtIGFIYXlzdGFjayBUaGUgYXJyYXkgdGhhdCBpcyBiZWluZyBzZWFyY2hlZC5cbiAqIEBwYXJhbSBhQ29tcGFyZSBBIGZ1bmN0aW9uIHdoaWNoIHRha2VzIHRoZSBuZWVkbGUgYW5kIGFuIGVsZW1lbnQgaW4gdGhlXG4gKiAgICAgYXJyYXkgYW5kIHJldHVybnMgLTEsIDAsIG9yIDEgZGVwZW5kaW5nIG9uIHdoZXRoZXIgdGhlIG5lZWRsZSBpcyBsZXNzXG4gKiAgICAgdGhhbiwgZXF1YWwgdG8sIG9yIGdyZWF0ZXIgdGhhbiB0aGUgZWxlbWVudCwgcmVzcGVjdGl2ZWx5LlxuICogQHBhcmFtIGFCaWFzIEVpdGhlciAnYmluYXJ5U2VhcmNoLkdSRUFURVNUX0xPV0VSX0JPVU5EJyBvclxuICogICAgICdiaW5hcnlTZWFyY2guTEVBU1RfVVBQRVJfQk9VTkQnLiBTcGVjaWZpZXMgd2hldGhlciB0byByZXR1cm4gdGhlXG4gKiAgICAgY2xvc2VzdCBlbGVtZW50IHRoYXQgaXMgc21hbGxlciB0aGFuIG9yIGdyZWF0ZXIgdGhhbiB0aGUgb25lIHdlIGFyZVxuICogICAgIHNlYXJjaGluZyBmb3IsIHJlc3BlY3RpdmVseSwgaWYgdGhlIGV4YWN0IGVsZW1lbnQgY2Fubm90IGJlIGZvdW5kLlxuICogICAgIERlZmF1bHRzIHRvICdiaW5hcnlTZWFyY2guR1JFQVRFU1RfTE9XRVJfQk9VTkQnLlxuICovXG5leHBvcnRzLnNlYXJjaCA9IGZ1bmN0aW9uIHNlYXJjaChhTmVlZGxlLCBhSGF5c3RhY2ssIGFDb21wYXJlLCBhQmlhcykge1xuICBpZiAoYUhheXN0YWNrLmxlbmd0aCA9PT0gMCkge1xuICAgIHJldHVybiAtMTtcbiAgfVxuXG4gIHZhciBpbmRleCA9IHJlY3Vyc2l2ZVNlYXJjaCgtMSwgYUhheXN0YWNrLmxlbmd0aCwgYU5lZWRsZSwgYUhheXN0YWNrLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYUNvbXBhcmUsIGFCaWFzIHx8IGV4cG9ydHMuR1JFQVRFU1RfTE9XRVJfQk9VTkQpO1xuICBpZiAoaW5kZXggPCAwKSB7XG4gICAgcmV0dXJuIC0xO1xuICB9XG5cbiAgLy8gV2UgaGF2ZSBmb3VuZCBlaXRoZXIgdGhlIGV4YWN0IGVsZW1lbnQsIG9yIHRoZSBuZXh0LWNsb3Nlc3QgZWxlbWVudCB0aGFuXG4gIC8vIHRoZSBvbmUgd2UgYXJlIHNlYXJjaGluZyBmb3IuIEhvd2V2ZXIsIHRoZXJlIG1heSBiZSBtb3JlIHRoYW4gb25lIHN1Y2hcbiAgLy8gZWxlbWVudC4gTWFrZSBzdXJlIHdlIGFsd2F5cyByZXR1cm4gdGhlIHNtYWxsZXN0IG9mIHRoZXNlLlxuICB3aGlsZSAoaW5kZXggLSAxID49IDApIHtcbiAgICBpZiAoYUNvbXBhcmUoYUhheXN0YWNrW2luZGV4XSwgYUhheXN0YWNrW2luZGV4IC0gMV0sIHRydWUpICE9PSAwKSB7XG4gICAgICBicmVhaztcbiAgICB9XG4gICAgLS1pbmRleDtcbiAgfVxuXG4gIHJldHVybiBpbmRleDtcbn07XG4iLCAiLyogLSotIE1vZGU6IGpzOyBqcy1pbmRlbnQtbGV2ZWw6IDI7IC0qLSAqL1xuLypcbiAqIENvcHlyaWdodCAyMDExIE1vemlsbGEgRm91bmRhdGlvbiBhbmQgY29udHJpYnV0b3JzXG4gKiBMaWNlbnNlZCB1bmRlciB0aGUgTmV3IEJTRCBsaWNlbnNlLiBTZWUgTElDRU5TRSBvcjpcbiAqIGh0dHA6Ly9vcGVuc291cmNlLm9yZy9saWNlbnNlcy9CU0QtMy1DbGF1c2VcbiAqL1xuXG4vLyBJdCB0dXJucyBvdXQgdGhhdCBzb21lIChtb3N0PykgSmF2YVNjcmlwdCBlbmdpbmVzIGRvbid0IHNlbGYtaG9zdFxuLy8gYEFycmF5LnByb3RvdHlwZS5zb3J0YC4gVGhpcyBtYWtlcyBzZW5zZSBiZWNhdXNlIEMrKyB3aWxsIGxpa2VseSByZW1haW5cbi8vIGZhc3RlciB0aGFuIEpTIHdoZW4gZG9pbmcgcmF3IENQVS1pbnRlbnNpdmUgc29ydGluZy4gSG93ZXZlciwgd2hlbiB1c2luZyBhXG4vLyBjdXN0b20gY29tcGFyYXRvciBmdW5jdGlvbiwgY2FsbGluZyBiYWNrIGFuZCBmb3J0aCBiZXR3ZWVuIHRoZSBWTSdzIEMrKyBhbmRcbi8vIEpJVCdkIEpTIGlzIHJhdGhlciBzbG93ICphbmQqIGxvc2VzIEpJVCB0eXBlIGluZm9ybWF0aW9uLCByZXN1bHRpbmcgaW5cbi8vIHdvcnNlIGdlbmVyYXRlZCBjb2RlIGZvciB0aGUgY29tcGFyYXRvciBmdW5jdGlvbiB0aGFuIHdvdWxkIGJlIG9wdGltYWwuIEluXG4vLyBmYWN0LCB3aGVuIHNvcnRpbmcgd2l0aCBhIGNvbXBhcmF0b3IsIHRoZXNlIGNvc3RzIG91dHdlaWdoIHRoZSBiZW5lZml0cyBvZlxuLy8gc29ydGluZyBpbiBDKysuIEJ5IHVzaW5nIG91ciBvd24gSlMtaW1wbGVtZW50ZWQgUXVpY2sgU29ydCAoYmVsb3cpLCB3ZSBnZXRcbi8vIGEgfjM1MDBtcyBtZWFuIHNwZWVkLXVwIGluIGBiZW5jaC9iZW5jaC5odG1sYC5cblxuZnVuY3Rpb24gU29ydFRlbXBsYXRlKGNvbXBhcmF0b3IpIHtcblxuLyoqXG4gKiBTd2FwIHRoZSBlbGVtZW50cyBpbmRleGVkIGJ5IGB4YCBhbmQgYHlgIGluIHRoZSBhcnJheSBgYXJ5YC5cbiAqXG4gKiBAcGFyYW0ge0FycmF5fSBhcnlcbiAqICAgICAgICBUaGUgYXJyYXkuXG4gKiBAcGFyYW0ge051bWJlcn0geFxuICogICAgICAgIFRoZSBpbmRleCBvZiB0aGUgZmlyc3QgaXRlbS5cbiAqIEBwYXJhbSB7TnVtYmVyfSB5XG4gKiAgICAgICAgVGhlIGluZGV4IG9mIHRoZSBzZWNvbmQgaXRlbS5cbiAqL1xuZnVuY3Rpb24gc3dhcChhcnksIHgsIHkpIHtcbiAgdmFyIHRlbXAgPSBhcnlbeF07XG4gIGFyeVt4XSA9IGFyeVt5XTtcbiAgYXJ5W3ldID0gdGVtcDtcbn1cblxuLyoqXG4gKiBSZXR1cm5zIGEgcmFuZG9tIGludGVnZXIgd2l0aGluIHRoZSByYW5nZSBgbG93IC4uIGhpZ2hgIGluY2x1c2l2ZS5cbiAqXG4gKiBAcGFyYW0ge051bWJlcn0gbG93XG4gKiAgICAgICAgVGhlIGxvd2VyIGJvdW5kIG9uIHRoZSByYW5nZS5cbiAqIEBwYXJhbSB7TnVtYmVyfSBoaWdoXG4gKiAgICAgICAgVGhlIHVwcGVyIGJvdW5kIG9uIHRoZSByYW5nZS5cbiAqL1xuZnVuY3Rpb24gcmFuZG9tSW50SW5SYW5nZShsb3csIGhpZ2gpIHtcbiAgcmV0dXJuIE1hdGgucm91bmQobG93ICsgKE1hdGgucmFuZG9tKCkgKiAoaGlnaCAtIGxvdykpKTtcbn1cblxuLyoqXG4gKiBUaGUgUXVpY2sgU29ydCBhbGdvcml0aG0uXG4gKlxuICogQHBhcmFtIHtBcnJheX0gYXJ5XG4gKiAgICAgICAgQW4gYXJyYXkgdG8gc29ydC5cbiAqIEBwYXJhbSB7ZnVuY3Rpb259IGNvbXBhcmF0b3JcbiAqICAgICAgICBGdW5jdGlvbiB0byB1c2UgdG8gY29tcGFyZSB0d28gaXRlbXMuXG4gKiBAcGFyYW0ge051bWJlcn0gcFxuICogICAgICAgIFN0YXJ0IGluZGV4IG9mIHRoZSBhcnJheVxuICogQHBhcmFtIHtOdW1iZXJ9IHJcbiAqICAgICAgICBFbmQgaW5kZXggb2YgdGhlIGFycmF5XG4gKi9cbmZ1bmN0aW9uIGRvUXVpY2tTb3J0KGFyeSwgY29tcGFyYXRvciwgcCwgcikge1xuICAvLyBJZiBvdXIgbG93ZXIgYm91bmQgaXMgbGVzcyB0aGFuIG91ciB1cHBlciBib3VuZCwgd2UgKDEpIHBhcnRpdGlvbiB0aGVcbiAgLy8gYXJyYXkgaW50byB0d28gcGllY2VzIGFuZCAoMikgcmVjdXJzZSBvbiBlYWNoIGhhbGYuIElmIGl0IGlzIG5vdCwgdGhpcyBpc1xuICAvLyB0aGUgZW1wdHkgYXJyYXkgYW5kIG91ciBiYXNlIGNhc2UuXG5cbiAgaWYgKHAgPCByKSB7XG4gICAgLy8gKDEpIFBhcnRpdGlvbmluZy5cbiAgICAvL1xuICAgIC8vIFRoZSBwYXJ0aXRpb25pbmcgY2hvb3NlcyBhIHBpdm90IGJldHdlZW4gYHBgIGFuZCBgcmAgYW5kIG1vdmVzIGFsbFxuICAgIC8vIGVsZW1lbnRzIHRoYXQgYXJlIGxlc3MgdGhhbiBvciBlcXVhbCB0byB0aGUgcGl2b3QgdG8gdGhlIGJlZm9yZSBpdCwgYW5kXG4gICAgLy8gYWxsIHRoZSBlbGVtZW50cyB0aGF0IGFyZSBncmVhdGVyIHRoYW4gaXQgYWZ0ZXIgaXQuIFRoZSBlZmZlY3QgaXMgdGhhdFxuICAgIC8vIG9uY2UgcGFydGl0aW9uIGlzIGRvbmUsIHRoZSBwaXZvdCBpcyBpbiB0aGUgZXhhY3QgcGxhY2UgaXQgd2lsbCBiZSB3aGVuXG4gICAgLy8gdGhlIGFycmF5IGlzIHB1dCBpbiBzb3J0ZWQgb3JkZXIsIGFuZCBpdCB3aWxsIG5vdCBuZWVkIHRvIGJlIG1vdmVkXG4gICAgLy8gYWdhaW4uIFRoaXMgcnVucyBpbiBPKG4pIHRpbWUuXG5cbiAgICAvLyBBbHdheXMgY2hvb3NlIGEgcmFuZG9tIHBpdm90IHNvIHRoYXQgYW4gaW5wdXQgYXJyYXkgd2hpY2ggaXMgcmV2ZXJzZVxuICAgIC8vIHNvcnRlZCBkb2VzIG5vdCBjYXVzZSBPKG5eMikgcnVubmluZyB0aW1lLlxuICAgIHZhciBwaXZvdEluZGV4ID0gcmFuZG9tSW50SW5SYW5nZShwLCByKTtcbiAgICB2YXIgaSA9IHAgLSAxO1xuXG4gICAgc3dhcChhcnksIHBpdm90SW5kZXgsIHIpO1xuICAgIHZhciBwaXZvdCA9IGFyeVtyXTtcblxuICAgIC8vIEltbWVkaWF0ZWx5IGFmdGVyIGBqYCBpcyBpbmNyZW1lbnRlZCBpbiB0aGlzIGxvb3AsIHRoZSBmb2xsb3dpbmcgaG9sZFxuICAgIC8vIHRydWU6XG4gICAgLy9cbiAgICAvLyAgICogRXZlcnkgZWxlbWVudCBpbiBgYXJ5W3AgLi4gaV1gIGlzIGxlc3MgdGhhbiBvciBlcXVhbCB0byB0aGUgcGl2b3QuXG4gICAgLy9cbiAgICAvLyAgICogRXZlcnkgZWxlbWVudCBpbiBgYXJ5W2krMSAuLiBqLTFdYCBpcyBncmVhdGVyIHRoYW4gdGhlIHBpdm90LlxuICAgIGZvciAodmFyIGogPSBwOyBqIDwgcjsgaisrKSB7XG4gICAgICBpZiAoY29tcGFyYXRvcihhcnlbal0sIHBpdm90LCBmYWxzZSkgPD0gMCkge1xuICAgICAgICBpICs9IDE7XG4gICAgICAgIHN3YXAoYXJ5LCBpLCBqKTtcbiAgICAgIH1cbiAgICB9XG5cbiAgICBzd2FwKGFyeSwgaSArIDEsIGopO1xuICAgIHZhciBxID0gaSArIDE7XG5cbiAgICAvLyAoMikgUmVjdXJzZSBvbiBlYWNoIGhhbGYuXG5cbiAgICBkb1F1aWNrU29ydChhcnksIGNvbXBhcmF0b3IsIHAsIHEgLSAxKTtcbiAgICBkb1F1aWNrU29ydChhcnksIGNvbXBhcmF0b3IsIHEgKyAxLCByKTtcbiAgfVxufVxuXG4gIHJldHVybiBkb1F1aWNrU29ydDtcbn1cblxuZnVuY3Rpb24gY2xvbmVTb3J0KGNvbXBhcmF0b3IpIHtcbiAgbGV0IHRlbXBsYXRlID0gU29ydFRlbXBsYXRlLnRvU3RyaW5nKCk7XG4gIGxldCB0ZW1wbGF0ZUZuID0gbmV3IEZ1bmN0aW9uKGByZXR1cm4gJHt0ZW1wbGF0ZX1gKSgpO1xuICByZXR1cm4gdGVtcGxhdGVGbihjb21wYXJhdG9yKTtcbn1cblxuLyoqXG4gKiBTb3J0IHRoZSBnaXZlbiBhcnJheSBpbi1wbGFjZSB3aXRoIHRoZSBnaXZlbiBjb21wYXJhdG9yIGZ1bmN0aW9uLlxuICpcbiAqIEBwYXJhbSB7QXJyYXl9IGFyeVxuICogICAgICAgIEFuIGFycmF5IHRvIHNvcnQuXG4gKiBAcGFyYW0ge2Z1bmN0aW9ufSBjb21wYXJhdG9yXG4gKiAgICAgICAgRnVuY3Rpb24gdG8gdXNlIHRvIGNvbXBhcmUgdHdvIGl0ZW1zLlxuICovXG5cbmxldCBzb3J0Q2FjaGUgPSBuZXcgV2Vha01hcCgpO1xuZXhwb3J0cy5xdWlja1NvcnQgPSBmdW5jdGlvbiAoYXJ5LCBjb21wYXJhdG9yLCBzdGFydCA9IDApIHtcbiAgbGV0IGRvUXVpY2tTb3J0ID0gc29ydENhY2hlLmdldChjb21wYXJhdG9yKTtcbiAgaWYgKGRvUXVpY2tTb3J0ID09PSB2b2lkIDApIHtcbiAgICBkb1F1aWNrU29ydCA9IGNsb25lU29ydChjb21wYXJhdG9yKTtcbiAgICBzb3J0Q2FjaGUuc2V0KGNvbXBhcmF0b3IsIGRvUXVpY2tTb3J0KTtcbiAgfVxuICBkb1F1aWNrU29ydChhcnksIGNvbXBhcmF0b3IsIHN0YXJ0LCBhcnkubGVuZ3RoIC0gMSk7XG59O1xuIiwgIi8qIC0qLSBNb2RlOiBqczsganMtaW5kZW50LWxldmVsOiAyOyAtKi0gKi9cbi8qXG4gKiBDb3B5cmlnaHQgMjAxMSBNb3ppbGxhIEZvdW5kYXRpb24gYW5kIGNvbnRyaWJ1dG9yc1xuICogTGljZW5zZWQgdW5kZXIgdGhlIE5ldyBCU0QgbGljZW5zZS4gU2VlIExJQ0VOU0Ugb3I6XG4gKiBodHRwOi8vb3BlbnNvdXJjZS5vcmcvbGljZW5zZXMvQlNELTMtQ2xhdXNlXG4gKi9cblxudmFyIHV0aWwgPSByZXF1aXJlKCcuL3V0aWwnKTtcbnZhciBiaW5hcnlTZWFyY2ggPSByZXF1aXJlKCcuL2JpbmFyeS1zZWFyY2gnKTtcbnZhciBBcnJheVNldCA9IHJlcXVpcmUoJy4vYXJyYXktc2V0JykuQXJyYXlTZXQ7XG52YXIgYmFzZTY0VkxRID0gcmVxdWlyZSgnLi9iYXNlNjQtdmxxJyk7XG52YXIgcXVpY2tTb3J0ID0gcmVxdWlyZSgnLi9xdWljay1zb3J0JykucXVpY2tTb3J0O1xuXG5mdW5jdGlvbiBTb3VyY2VNYXBDb25zdW1lcihhU291cmNlTWFwLCBhU291cmNlTWFwVVJMKSB7XG4gIHZhciBzb3VyY2VNYXAgPSBhU291cmNlTWFwO1xuICBpZiAodHlwZW9mIGFTb3VyY2VNYXAgPT09ICdzdHJpbmcnKSB7XG4gICAgc291cmNlTWFwID0gdXRpbC5wYXJzZVNvdXJjZU1hcElucHV0KGFTb3VyY2VNYXApO1xuICB9XG5cbiAgcmV0dXJuIHNvdXJjZU1hcC5zZWN0aW9ucyAhPSBudWxsXG4gICAgPyBuZXcgSW5kZXhlZFNvdXJjZU1hcENvbnN1bWVyKHNvdXJjZU1hcCwgYVNvdXJjZU1hcFVSTClcbiAgICA6IG5ldyBCYXNpY1NvdXJjZU1hcENvbnN1bWVyKHNvdXJjZU1hcCwgYVNvdXJjZU1hcFVSTCk7XG59XG5cblNvdXJjZU1hcENvbnN1bWVyLmZyb21Tb3VyY2VNYXAgPSBmdW5jdGlvbihhU291cmNlTWFwLCBhU291cmNlTWFwVVJMKSB7XG4gIHJldHVybiBCYXNpY1NvdXJjZU1hcENvbnN1bWVyLmZyb21Tb3VyY2VNYXAoYVNvdXJjZU1hcCwgYVNvdXJjZU1hcFVSTCk7XG59XG5cbi8qKlxuICogVGhlIHZlcnNpb24gb2YgdGhlIHNvdXJjZSBtYXBwaW5nIHNwZWMgdGhhdCB3ZSBhcmUgY29uc3VtaW5nLlxuICovXG5Tb3VyY2VNYXBDb25zdW1lci5wcm90b3R5cGUuX3ZlcnNpb24gPSAzO1xuXG4vLyBgX19nZW5lcmF0ZWRNYXBwaW5nc2AgYW5kIGBfX29yaWdpbmFsTWFwcGluZ3NgIGFyZSBhcnJheXMgdGhhdCBob2xkIHRoZVxuLy8gcGFyc2VkIG1hcHBpbmcgY29vcmRpbmF0ZXMgZnJvbSB0aGUgc291cmNlIG1hcCdzIFwibWFwcGluZ3NcIiBhdHRyaWJ1dGUuIFRoZXlcbi8vIGFyZSBsYXppbHkgaW5zdGFudGlhdGVkLCBhY2Nlc3NlZCB2aWEgdGhlIGBfZ2VuZXJhdGVkTWFwcGluZ3NgIGFuZFxuLy8gYF9vcmlnaW5hbE1hcHBpbmdzYCBnZXR0ZXJzIHJlc3BlY3RpdmVseSwgYW5kIHdlIG9ubHkgcGFyc2UgdGhlIG1hcHBpbmdzXG4vLyBhbmQgY3JlYXRlIHRoZXNlIGFycmF5cyBvbmNlIHF1ZXJpZWQgZm9yIGEgc291cmNlIGxvY2F0aW9uLiBXZSBqdW1wIHRocm91Z2hcbi8vIHRoZXNlIGhvb3BzIGJlY2F1c2UgdGhlcmUgY2FuIGJlIG1hbnkgdGhvdXNhbmRzIG9mIG1hcHBpbmdzLCBhbmQgcGFyc2luZ1xuLy8gdGhlbSBpcyBleHBlbnNpdmUsIHNvIHdlIG9ubHkgd2FudCB0byBkbyBpdCBpZiB3ZSBtdXN0LlxuLy9cbi8vIEVhY2ggb2JqZWN0IGluIHRoZSBhcnJheXMgaXMgb2YgdGhlIGZvcm06XG4vL1xuLy8gICAgIHtcbi8vICAgICAgIGdlbmVyYXRlZExpbmU6IFRoZSBsaW5lIG51bWJlciBpbiB0aGUgZ2VuZXJhdGVkIGNvZGUsXG4vLyAgICAgICBnZW5lcmF0ZWRDb2x1bW46IFRoZSBjb2x1bW4gbnVtYmVyIGluIHRoZSBnZW5lcmF0ZWQgY29kZSxcbi8vICAgICAgIHNvdXJjZTogVGhlIHBhdGggdG8gdGhlIG9yaWdpbmFsIHNvdXJjZSBmaWxlIHRoYXQgZ2VuZXJhdGVkIHRoaXNcbi8vICAgICAgICAgICAgICAgY2h1bmsgb2YgY29kZSxcbi8vICAgICAgIG9yaWdpbmFsTGluZTogVGhlIGxpbmUgbnVtYmVyIGluIHRoZSBvcmlnaW5hbCBzb3VyY2UgdGhhdFxuLy8gICAgICAgICAgICAgICAgICAgICBjb3JyZXNwb25kcyB0byB0aGlzIGNodW5rIG9mIGdlbmVyYXRlZCBjb2RlLFxuLy8gICAgICAgb3JpZ2luYWxDb2x1bW46IFRoZSBjb2x1bW4gbnVtYmVyIGluIHRoZSBvcmlnaW5hbCBzb3VyY2UgdGhhdFxuLy8gICAgICAgICAgICAgICAgICAgICAgIGNvcnJlc3BvbmRzIHRvIHRoaXMgY2h1bmsgb2YgZ2VuZXJhdGVkIGNvZGUsXG4vLyAgICAgICBuYW1lOiBUaGUgbmFtZSBvZiB0aGUgb3JpZ2luYWwgc3ltYm9sIHdoaWNoIGdlbmVyYXRlZCB0aGlzIGNodW5rIG9mXG4vLyAgICAgICAgICAgICBjb2RlLlxuLy8gICAgIH1cbi8vXG4vLyBBbGwgcHJvcGVydGllcyBleGNlcHQgZm9yIGBnZW5lcmF0ZWRMaW5lYCBhbmQgYGdlbmVyYXRlZENvbHVtbmAgY2FuIGJlXG4vLyBgbnVsbGAuXG4vL1xuLy8gYF9nZW5lcmF0ZWRNYXBwaW5nc2AgaXMgb3JkZXJlZCBieSB0aGUgZ2VuZXJhdGVkIHBvc2l0aW9ucy5cbi8vXG4vLyBgX29yaWdpbmFsTWFwcGluZ3NgIGlzIG9yZGVyZWQgYnkgdGhlIG9yaWdpbmFsIHBvc2l0aW9ucy5cblxuU291cmNlTWFwQ29uc3VtZXIucHJvdG90eXBlLl9fZ2VuZXJhdGVkTWFwcGluZ3MgPSBudWxsO1xuT2JqZWN0LmRlZmluZVByb3BlcnR5KFNvdXJjZU1hcENvbnN1bWVyLnByb3RvdHlwZSwgJ19nZW5lcmF0ZWRNYXBwaW5ncycsIHtcbiAgY29uZmlndXJhYmxlOiB0cnVlLFxuICBlbnVtZXJhYmxlOiB0cnVlLFxuICBnZXQ6IGZ1bmN0aW9uICgpIHtcbiAgICBpZiAoIXRoaXMuX19nZW5lcmF0ZWRNYXBwaW5ncykge1xuICAgICAgdGhpcy5fcGFyc2VNYXBwaW5ncyh0aGlzLl9tYXBwaW5ncywgdGhpcy5zb3VyY2VSb290KTtcbiAgICB9XG5cbiAgICByZXR1cm4gdGhpcy5fX2dlbmVyYXRlZE1hcHBpbmdzO1xuICB9XG59KTtcblxuU291cmNlTWFwQ29uc3VtZXIucHJvdG90eXBlLl9fb3JpZ2luYWxNYXBwaW5ncyA9IG51bGw7XG5PYmplY3QuZGVmaW5lUHJvcGVydHkoU291cmNlTWFwQ29uc3VtZXIucHJvdG90eXBlLCAnX29yaWdpbmFsTWFwcGluZ3MnLCB7XG4gIGNvbmZpZ3VyYWJsZTogdHJ1ZSxcbiAgZW51bWVyYWJsZTogdHJ1ZSxcbiAgZ2V0OiBmdW5jdGlvbiAoKSB7XG4gICAgaWYgKCF0aGlzLl9fb3JpZ2luYWxNYXBwaW5ncykge1xuICAgICAgdGhpcy5fcGFyc2VNYXBwaW5ncyh0aGlzLl9tYXBwaW5ncywgdGhpcy5zb3VyY2VSb290KTtcbiAgICB9XG5cbiAgICByZXR1cm4gdGhpcy5fX29yaWdpbmFsTWFwcGluZ3M7XG4gIH1cbn0pO1xuXG5Tb3VyY2VNYXBDb25zdW1lci5wcm90b3R5cGUuX2NoYXJJc01hcHBpbmdTZXBhcmF0b3IgPVxuICBmdW5jdGlvbiBTb3VyY2VNYXBDb25zdW1lcl9jaGFySXNNYXBwaW5nU2VwYXJhdG9yKGFTdHIsIGluZGV4KSB7XG4gICAgdmFyIGMgPSBhU3RyLmNoYXJBdChpbmRleCk7XG4gICAgcmV0dXJuIGMgPT09IFwiO1wiIHx8IGMgPT09IFwiLFwiO1xuICB9O1xuXG4vKipcbiAqIFBhcnNlIHRoZSBtYXBwaW5ncyBpbiBhIHN0cmluZyBpbiB0byBhIGRhdGEgc3RydWN0dXJlIHdoaWNoIHdlIGNhbiBlYXNpbHlcbiAqIHF1ZXJ5ICh0aGUgb3JkZXJlZCBhcnJheXMgaW4gdGhlIGB0aGlzLl9fZ2VuZXJhdGVkTWFwcGluZ3NgIGFuZFxuICogYHRoaXMuX19vcmlnaW5hbE1hcHBpbmdzYCBwcm9wZXJ0aWVzKS5cbiAqL1xuU291cmNlTWFwQ29uc3VtZXIucHJvdG90eXBlLl9wYXJzZU1hcHBpbmdzID1cbiAgZnVuY3Rpb24gU291cmNlTWFwQ29uc3VtZXJfcGFyc2VNYXBwaW5ncyhhU3RyLCBhU291cmNlUm9vdCkge1xuICAgIHRocm93IG5ldyBFcnJvcihcIlN1YmNsYXNzZXMgbXVzdCBpbXBsZW1lbnQgX3BhcnNlTWFwcGluZ3NcIik7XG4gIH07XG5cblNvdXJjZU1hcENvbnN1bWVyLkdFTkVSQVRFRF9PUkRFUiA9IDE7XG5Tb3VyY2VNYXBDb25zdW1lci5PUklHSU5BTF9PUkRFUiA9IDI7XG5cblNvdXJjZU1hcENvbnN1bWVyLkdSRUFURVNUX0xPV0VSX0JPVU5EID0gMTtcblNvdXJjZU1hcENvbnN1bWVyLkxFQVNUX1VQUEVSX0JPVU5EID0gMjtcblxuLyoqXG4gKiBJdGVyYXRlIG92ZXIgZWFjaCBtYXBwaW5nIGJldHdlZW4gYW4gb3JpZ2luYWwgc291cmNlL2xpbmUvY29sdW1uIGFuZCBhXG4gKiBnZW5lcmF0ZWQgbGluZS9jb2x1bW4gaW4gdGhpcyBzb3VyY2UgbWFwLlxuICpcbiAqIEBwYXJhbSBGdW5jdGlvbiBhQ2FsbGJhY2tcbiAqICAgICAgICBUaGUgZnVuY3Rpb24gdGhhdCBpcyBjYWxsZWQgd2l0aCBlYWNoIG1hcHBpbmcuXG4gKiBAcGFyYW0gT2JqZWN0IGFDb250ZXh0XG4gKiAgICAgICAgT3B0aW9uYWwuIElmIHNwZWNpZmllZCwgdGhpcyBvYmplY3Qgd2lsbCBiZSB0aGUgdmFsdWUgb2YgYHRoaXNgIGV2ZXJ5XG4gKiAgICAgICAgdGltZSB0aGF0IGBhQ2FsbGJhY2tgIGlzIGNhbGxlZC5cbiAqIEBwYXJhbSBhT3JkZXJcbiAqICAgICAgICBFaXRoZXIgYFNvdXJjZU1hcENvbnN1bWVyLkdFTkVSQVRFRF9PUkRFUmAgb3JcbiAqICAgICAgICBgU291cmNlTWFwQ29uc3VtZXIuT1JJR0lOQUxfT1JERVJgLiBTcGVjaWZpZXMgd2hldGhlciB5b3Ugd2FudCB0b1xuICogICAgICAgIGl0ZXJhdGUgb3ZlciB0aGUgbWFwcGluZ3Mgc29ydGVkIGJ5IHRoZSBnZW5lcmF0ZWQgZmlsZSdzIGxpbmUvY29sdW1uXG4gKiAgICAgICAgb3JkZXIgb3IgdGhlIG9yaWdpbmFsJ3Mgc291cmNlL2xpbmUvY29sdW1uIG9yZGVyLCByZXNwZWN0aXZlbHkuIERlZmF1bHRzIHRvXG4gKiAgICAgICAgYFNvdXJjZU1hcENvbnN1bWVyLkdFTkVSQVRFRF9PUkRFUmAuXG4gKi9cblNvdXJjZU1hcENvbnN1bWVyLnByb3RvdHlwZS5lYWNoTWFwcGluZyA9XG4gIGZ1bmN0aW9uIFNvdXJjZU1hcENvbnN1bWVyX2VhY2hNYXBwaW5nKGFDYWxsYmFjaywgYUNvbnRleHQsIGFPcmRlcikge1xuICAgIHZhciBjb250ZXh0ID0gYUNvbnRleHQgfHwgbnVsbDtcbiAgICB2YXIgb3JkZXIgPSBhT3JkZXIgfHwgU291cmNlTWFwQ29uc3VtZXIuR0VORVJBVEVEX09SREVSO1xuXG4gICAgdmFyIG1hcHBpbmdzO1xuICAgIHN3aXRjaCAob3JkZXIpIHtcbiAgICBjYXNlIFNvdXJjZU1hcENvbnN1bWVyLkdFTkVSQVRFRF9PUkRFUjpcbiAgICAgIG1hcHBpbmdzID0gdGhpcy5fZ2VuZXJhdGVkTWFwcGluZ3M7XG4gICAgICBicmVhaztcbiAgICBjYXNlIFNvdXJjZU1hcENvbnN1bWVyLk9SSUdJTkFMX09SREVSOlxuICAgICAgbWFwcGluZ3MgPSB0aGlzLl9vcmlnaW5hbE1hcHBpbmdzO1xuICAgICAgYnJlYWs7XG4gICAgZGVmYXVsdDpcbiAgICAgIHRocm93IG5ldyBFcnJvcihcIlVua25vd24gb3JkZXIgb2YgaXRlcmF0aW9uLlwiKTtcbiAgICB9XG5cbiAgICB2YXIgc291cmNlUm9vdCA9IHRoaXMuc291cmNlUm9vdDtcbiAgICB2YXIgYm91bmRDYWxsYmFjayA9IGFDYWxsYmFjay5iaW5kKGNvbnRleHQpO1xuICAgIHZhciBuYW1lcyA9IHRoaXMuX25hbWVzO1xuICAgIHZhciBzb3VyY2VzID0gdGhpcy5fc291cmNlcztcbiAgICB2YXIgc291cmNlTWFwVVJMID0gdGhpcy5fc291cmNlTWFwVVJMO1xuXG4gICAgZm9yICh2YXIgaSA9IDAsIG4gPSBtYXBwaW5ncy5sZW5ndGg7IGkgPCBuOyBpKyspIHtcbiAgICAgIHZhciBtYXBwaW5nID0gbWFwcGluZ3NbaV07XG4gICAgICB2YXIgc291cmNlID0gbWFwcGluZy5zb3VyY2UgPT09IG51bGwgPyBudWxsIDogc291cmNlcy5hdChtYXBwaW5nLnNvdXJjZSk7XG4gICAgICBpZihzb3VyY2UgIT09IG51bGwpIHtcbiAgICAgICAgc291cmNlID0gdXRpbC5jb21wdXRlU291cmNlVVJMKHNvdXJjZVJvb3QsIHNvdXJjZSwgc291cmNlTWFwVVJMKTtcbiAgICAgIH1cbiAgICAgIGJvdW5kQ2FsbGJhY2soe1xuICAgICAgICBzb3VyY2U6IHNvdXJjZSxcbiAgICAgICAgZ2VuZXJhdGVkTGluZTogbWFwcGluZy5nZW5lcmF0ZWRMaW5lLFxuICAgICAgICBnZW5lcmF0ZWRDb2x1bW46IG1hcHBpbmcuZ2VuZXJhdGVkQ29sdW1uLFxuICAgICAgICBvcmlnaW5hbExpbmU6IG1hcHBpbmcub3JpZ2luYWxMaW5lLFxuICAgICAgICBvcmlnaW5hbENvbHVtbjogbWFwcGluZy5vcmlnaW5hbENvbHVtbixcbiAgICAgICAgbmFtZTogbWFwcGluZy5uYW1lID09PSBudWxsID8gbnVsbCA6IG5hbWVzLmF0KG1hcHBpbmcubmFtZSlcbiAgICAgIH0pO1xuICAgIH1cbiAgfTtcblxuLyoqXG4gKiBSZXR1cm5zIGFsbCBnZW5lcmF0ZWQgbGluZSBhbmQgY29sdW1uIGluZm9ybWF0aW9uIGZvciB0aGUgb3JpZ2luYWwgc291cmNlLFxuICogbGluZSwgYW5kIGNvbHVtbiBwcm92aWRlZC4gSWYgbm8gY29sdW1uIGlzIHByb3ZpZGVkLCByZXR1cm5zIGFsbCBtYXBwaW5nc1xuICogY29ycmVzcG9uZGluZyB0byBhIGVpdGhlciB0aGUgbGluZSB3ZSBhcmUgc2VhcmNoaW5nIGZvciBvciB0aGUgbmV4dFxuICogY2xvc2VzdCBsaW5lIHRoYXQgaGFzIGFueSBtYXBwaW5ncy4gT3RoZXJ3aXNlLCByZXR1cm5zIGFsbCBtYXBwaW5nc1xuICogY29ycmVzcG9uZGluZyB0byB0aGUgZ2l2ZW4gbGluZSBhbmQgZWl0aGVyIHRoZSBjb2x1bW4gd2UgYXJlIHNlYXJjaGluZyBmb3JcbiAqIG9yIHRoZSBuZXh0IGNsb3Nlc3QgY29sdW1uIHRoYXQgaGFzIGFueSBvZmZzZXRzLlxuICpcbiAqIFRoZSBvbmx5IGFyZ3VtZW50IGlzIGFuIG9iamVjdCB3aXRoIHRoZSBmb2xsb3dpbmcgcHJvcGVydGllczpcbiAqXG4gKiAgIC0gc291cmNlOiBUaGUgZmlsZW5hbWUgb2YgdGhlIG9yaWdpbmFsIHNvdXJjZS5cbiAqICAgLSBsaW5lOiBUaGUgbGluZSBudW1iZXIgaW4gdGhlIG9yaWdpbmFsIHNvdXJjZS4gIFRoZSBsaW5lIG51bWJlciBpcyAxLWJhc2VkLlxuICogICAtIGNvbHVtbjogT3B0aW9uYWwuIHRoZSBjb2x1bW4gbnVtYmVyIGluIHRoZSBvcmlnaW5hbCBzb3VyY2UuXG4gKiAgICBUaGUgY29sdW1uIG51bWJlciBpcyAwLWJhc2VkLlxuICpcbiAqIGFuZCBhbiBhcnJheSBvZiBvYmplY3RzIGlzIHJldHVybmVkLCBlYWNoIHdpdGggdGhlIGZvbGxvd2luZyBwcm9wZXJ0aWVzOlxuICpcbiAqICAgLSBsaW5lOiBUaGUgbGluZSBudW1iZXIgaW4gdGhlIGdlbmVyYXRlZCBzb3VyY2UsIG9yIG51bGwuICBUaGVcbiAqICAgIGxpbmUgbnVtYmVyIGlzIDEtYmFzZWQuXG4gKiAgIC0gY29sdW1uOiBUaGUgY29sdW1uIG51bWJlciBpbiB0aGUgZ2VuZXJhdGVkIHNvdXJjZSwgb3IgbnVsbC5cbiAqICAgIFRoZSBjb2x1bW4gbnVtYmVyIGlzIDAtYmFzZWQuXG4gKi9cblNvdXJjZU1hcENvbnN1bWVyLnByb3RvdHlwZS5hbGxHZW5lcmF0ZWRQb3NpdGlvbnNGb3IgPVxuICBmdW5jdGlvbiBTb3VyY2VNYXBDb25zdW1lcl9hbGxHZW5lcmF0ZWRQb3NpdGlvbnNGb3IoYUFyZ3MpIHtcbiAgICB2YXIgbGluZSA9IHV0aWwuZ2V0QXJnKGFBcmdzLCAnbGluZScpO1xuXG4gICAgLy8gV2hlbiB0aGVyZSBpcyBubyBleGFjdCBtYXRjaCwgQmFzaWNTb3VyY2VNYXBDb25zdW1lci5wcm90b3R5cGUuX2ZpbmRNYXBwaW5nXG4gICAgLy8gcmV0dXJucyB0aGUgaW5kZXggb2YgdGhlIGNsb3Nlc3QgbWFwcGluZyBsZXNzIHRoYW4gdGhlIG5lZWRsZS4gQnlcbiAgICAvLyBzZXR0aW5nIG5lZWRsZS5vcmlnaW5hbENvbHVtbiB0byAwLCB3ZSB0aHVzIGZpbmQgdGhlIGxhc3QgbWFwcGluZyBmb3JcbiAgICAvLyB0aGUgZ2l2ZW4gbGluZSwgcHJvdmlkZWQgc3VjaCBhIG1hcHBpbmcgZXhpc3RzLlxuICAgIHZhciBuZWVkbGUgPSB7XG4gICAgICBzb3VyY2U6IHV0aWwuZ2V0QXJnKGFBcmdzLCAnc291cmNlJyksXG4gICAgICBvcmlnaW5hbExpbmU6IGxpbmUsXG4gICAgICBvcmlnaW5hbENvbHVtbjogdXRpbC5nZXRBcmcoYUFyZ3MsICdjb2x1bW4nLCAwKVxuICAgIH07XG5cbiAgICBuZWVkbGUuc291cmNlID0gdGhpcy5fZmluZFNvdXJjZUluZGV4KG5lZWRsZS5zb3VyY2UpO1xuICAgIGlmIChuZWVkbGUuc291cmNlIDwgMCkge1xuICAgICAgcmV0dXJuIFtdO1xuICAgIH1cblxuICAgIHZhciBtYXBwaW5ncyA9IFtdO1xuXG4gICAgdmFyIGluZGV4ID0gdGhpcy5fZmluZE1hcHBpbmcobmVlZGxlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRoaXMuX29yaWdpbmFsTWFwcGluZ3MsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgXCJvcmlnaW5hbExpbmVcIixcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBcIm9yaWdpbmFsQ29sdW1uXCIsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdXRpbC5jb21wYXJlQnlPcmlnaW5hbFBvc2l0aW9ucyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBiaW5hcnlTZWFyY2guTEVBU1RfVVBQRVJfQk9VTkQpO1xuICAgIGlmIChpbmRleCA+PSAwKSB7XG4gICAgICB2YXIgbWFwcGluZyA9IHRoaXMuX29yaWdpbmFsTWFwcGluZ3NbaW5kZXhdO1xuXG4gICAgICBpZiAoYUFyZ3MuY29sdW1uID09PSB1bmRlZmluZWQpIHtcbiAgICAgICAgdmFyIG9yaWdpbmFsTGluZSA9IG1hcHBpbmcub3JpZ2luYWxMaW5lO1xuXG4gICAgICAgIC8vIEl0ZXJhdGUgdW50aWwgZWl0aGVyIHdlIHJ1biBvdXQgb2YgbWFwcGluZ3MsIG9yIHdlIHJ1biBpbnRvXG4gICAgICAgIC8vIGEgbWFwcGluZyBmb3IgYSBkaWZmZXJlbnQgbGluZSB0aGFuIHRoZSBvbmUgd2UgZm91bmQuIFNpbmNlXG4gICAgICAgIC8vIG1hcHBpbmdzIGFyZSBzb3J0ZWQsIHRoaXMgaXMgZ3VhcmFudGVlZCB0byBmaW5kIGFsbCBtYXBwaW5ncyBmb3JcbiAgICAgICAgLy8gdGhlIGxpbmUgd2UgZm91bmQuXG4gICAgICAgIHdoaWxlIChtYXBwaW5nICYmIG1hcHBpbmcub3JpZ2luYWxMaW5lID09PSBvcmlnaW5hbExpbmUpIHtcbiAgICAgICAgICBtYXBwaW5ncy5wdXNoKHtcbiAgICAgICAgICAgIGxpbmU6IHV0aWwuZ2V0QXJnKG1hcHBpbmcsICdnZW5lcmF0ZWRMaW5lJywgbnVsbCksXG4gICAgICAgICAgICBjb2x1bW46IHV0aWwuZ2V0QXJnKG1hcHBpbmcsICdnZW5lcmF0ZWRDb2x1bW4nLCBudWxsKSxcbiAgICAgICAgICAgIGxhc3RDb2x1bW46IHV0aWwuZ2V0QXJnKG1hcHBpbmcsICdsYXN0R2VuZXJhdGVkQ29sdW1uJywgbnVsbClcbiAgICAgICAgICB9KTtcblxuICAgICAgICAgIG1hcHBpbmcgPSB0aGlzLl9vcmlnaW5hbE1hcHBpbmdzWysraW5kZXhdO1xuICAgICAgICB9XG4gICAgICB9IGVsc2Uge1xuICAgICAgICB2YXIgb3JpZ2luYWxDb2x1bW4gPSBtYXBwaW5nLm9yaWdpbmFsQ29sdW1uO1xuXG4gICAgICAgIC8vIEl0ZXJhdGUgdW50aWwgZWl0aGVyIHdlIHJ1biBvdXQgb2YgbWFwcGluZ3MsIG9yIHdlIHJ1biBpbnRvXG4gICAgICAgIC8vIGEgbWFwcGluZyBmb3IgYSBkaWZmZXJlbnQgbGluZSB0aGFuIHRoZSBvbmUgd2Ugd2VyZSBzZWFyY2hpbmcgZm9yLlxuICAgICAgICAvLyBTaW5jZSBtYXBwaW5ncyBhcmUgc29ydGVkLCB0aGlzIGlzIGd1YXJhbnRlZWQgdG8gZmluZCBhbGwgbWFwcGluZ3MgZm9yXG4gICAgICAgIC8vIHRoZSBsaW5lIHdlIGFyZSBzZWFyY2hpbmcgZm9yLlxuICAgICAgICB3aGlsZSAobWFwcGluZyAmJlxuICAgICAgICAgICAgICAgbWFwcGluZy5vcmlnaW5hbExpbmUgPT09IGxpbmUgJiZcbiAgICAgICAgICAgICAgIG1hcHBpbmcub3JpZ2luYWxDb2x1bW4gPT0gb3JpZ2luYWxDb2x1bW4pIHtcbiAgICAgICAgICBtYXBwaW5ncy5wdXNoKHtcbiAgICAgICAgICAgIGxpbmU6IHV0aWwuZ2V0QXJnKG1hcHBpbmcsICdnZW5lcmF0ZWRMaW5lJywgbnVsbCksXG4gICAgICAgICAgICBjb2x1bW46IHV0aWwuZ2V0QXJnKG1hcHBpbmcsICdnZW5lcmF0ZWRDb2x1bW4nLCBudWxsKSxcbiAgICAgICAgICAgIGxhc3RDb2x1bW46IHV0aWwuZ2V0QXJnKG1hcHBpbmcsICdsYXN0R2VuZXJhdGVkQ29sdW1uJywgbnVsbClcbiAgICAgICAgICB9KTtcblxuICAgICAgICAgIG1hcHBpbmcgPSB0aGlzLl9vcmlnaW5hbE1hcHBpbmdzWysraW5kZXhdO1xuICAgICAgICB9XG4gICAgICB9XG4gICAgfVxuXG4gICAgcmV0dXJuIG1hcHBpbmdzO1xuICB9O1xuXG5leHBvcnRzLlNvdXJjZU1hcENvbnN1bWVyID0gU291cmNlTWFwQ29uc3VtZXI7XG5cbi8qKlxuICogQSBCYXNpY1NvdXJjZU1hcENvbnN1bWVyIGluc3RhbmNlIHJlcHJlc2VudHMgYSBwYXJzZWQgc291cmNlIG1hcCB3aGljaCB3ZSBjYW5cbiAqIHF1ZXJ5IGZvciBpbmZvcm1hdGlvbiBhYm91dCB0aGUgb3JpZ2luYWwgZmlsZSBwb3NpdGlvbnMgYnkgZ2l2aW5nIGl0IGEgZmlsZVxuICogcG9zaXRpb24gaW4gdGhlIGdlbmVyYXRlZCBzb3VyY2UuXG4gKlxuICogVGhlIGZpcnN0IHBhcmFtZXRlciBpcyB0aGUgcmF3IHNvdXJjZSBtYXAgKGVpdGhlciBhcyBhIEpTT04gc3RyaW5nLCBvclxuICogYWxyZWFkeSBwYXJzZWQgdG8gYW4gb2JqZWN0KS4gQWNjb3JkaW5nIHRvIHRoZSBzcGVjLCBzb3VyY2UgbWFwcyBoYXZlIHRoZVxuICogZm9sbG93aW5nIGF0dHJpYnV0ZXM6XG4gKlxuICogICAtIHZlcnNpb246IFdoaWNoIHZlcnNpb24gb2YgdGhlIHNvdXJjZSBtYXAgc3BlYyB0aGlzIG1hcCBpcyBmb2xsb3dpbmcuXG4gKiAgIC0gc291cmNlczogQW4gYXJyYXkgb2YgVVJMcyB0byB0aGUgb3JpZ2luYWwgc291cmNlIGZpbGVzLlxuICogICAtIG5hbWVzOiBBbiBhcnJheSBvZiBpZGVudGlmaWVycyB3aGljaCBjYW4gYmUgcmVmZXJyZW5jZWQgYnkgaW5kaXZpZHVhbCBtYXBwaW5ncy5cbiAqICAgLSBzb3VyY2VSb290OiBPcHRpb25hbC4gVGhlIFVSTCByb290IGZyb20gd2hpY2ggYWxsIHNvdXJjZXMgYXJlIHJlbGF0aXZlLlxuICogICAtIHNvdXJjZXNDb250ZW50OiBPcHRpb25hbC4gQW4gYXJyYXkgb2YgY29udGVudHMgb2YgdGhlIG9yaWdpbmFsIHNvdXJjZSBmaWxlcy5cbiAqICAgLSBtYXBwaW5nczogQSBzdHJpbmcgb2YgYmFzZTY0IFZMUXMgd2hpY2ggY29udGFpbiB0aGUgYWN0dWFsIG1hcHBpbmdzLlxuICogICAtIGZpbGU6IE9wdGlvbmFsLiBUaGUgZ2VuZXJhdGVkIGZpbGUgdGhpcyBzb3VyY2UgbWFwIGlzIGFzc29jaWF0ZWQgd2l0aC5cbiAqXG4gKiBIZXJlIGlzIGFuIGV4YW1wbGUgc291cmNlIG1hcCwgdGFrZW4gZnJvbSB0aGUgc291cmNlIG1hcCBzcGVjWzBdOlxuICpcbiAqICAgICB7XG4gKiAgICAgICB2ZXJzaW9uIDogMyxcbiAqICAgICAgIGZpbGU6IFwib3V0LmpzXCIsXG4gKiAgICAgICBzb3VyY2VSb290IDogXCJcIixcbiAqICAgICAgIHNvdXJjZXM6IFtcImZvby5qc1wiLCBcImJhci5qc1wiXSxcbiAqICAgICAgIG5hbWVzOiBbXCJzcmNcIiwgXCJtYXBzXCIsIFwiYXJlXCIsIFwiZnVuXCJdLFxuICogICAgICAgbWFwcGluZ3M6IFwiQUEsQUI7O0FCQ0RFO1wiXG4gKiAgICAgfVxuICpcbiAqIFRoZSBzZWNvbmQgcGFyYW1ldGVyLCBpZiBnaXZlbiwgaXMgYSBzdHJpbmcgd2hvc2UgdmFsdWUgaXMgdGhlIFVSTFxuICogYXQgd2hpY2ggdGhlIHNvdXJjZSBtYXAgd2FzIGZvdW5kLiAgVGhpcyBVUkwgaXMgdXNlZCB0byBjb21wdXRlIHRoZVxuICogc291cmNlcyBhcnJheS5cbiAqXG4gKiBbMF06IGh0dHBzOi8vZG9jcy5nb29nbGUuY29tL2RvY3VtZW50L2QvMVUxUkdBZWhRd1J5cFVUb3ZGMUtSbHBpT0Z6ZTBiLV8yZ2M2ZkFIMEtZMGsvZWRpdD9wbGk9MSNcbiAqL1xuZnVuY3Rpb24gQmFzaWNTb3VyY2VNYXBDb25zdW1lcihhU291cmNlTWFwLCBhU291cmNlTWFwVVJMKSB7XG4gIHZhciBzb3VyY2VNYXAgPSBhU291cmNlTWFwO1xuICBpZiAodHlwZW9mIGFTb3VyY2VNYXAgPT09ICdzdHJpbmcnKSB7XG4gICAgc291cmNlTWFwID0gdXRpbC5wYXJzZVNvdXJjZU1hcElucHV0KGFTb3VyY2VNYXApO1xuICB9XG5cbiAgdmFyIHZlcnNpb24gPSB1dGlsLmdldEFyZyhzb3VyY2VNYXAsICd2ZXJzaW9uJyk7XG4gIHZhciBzb3VyY2VzID0gdXRpbC5nZXRBcmcoc291cmNlTWFwLCAnc291cmNlcycpO1xuICAvLyBTYXNzIDMuMyBsZWF2ZXMgb3V0IHRoZSAnbmFtZXMnIGFycmF5LCBzbyB3ZSBkZXZpYXRlIGZyb20gdGhlIHNwZWMgKHdoaWNoXG4gIC8vIHJlcXVpcmVzIHRoZSBhcnJheSkgdG8gcGxheSBuaWNlIGhlcmUuXG4gIHZhciBuYW1lcyA9IHV0aWwuZ2V0QXJnKHNvdXJjZU1hcCwgJ25hbWVzJywgW10pO1xuICB2YXIgc291cmNlUm9vdCA9IHV0aWwuZ2V0QXJnKHNvdXJjZU1hcCwgJ3NvdXJjZVJvb3QnLCBudWxsKTtcbiAgdmFyIHNvdXJjZXNDb250ZW50ID0gdXRpbC5nZXRBcmcoc291cmNlTWFwLCAnc291cmNlc0NvbnRlbnQnLCBudWxsKTtcbiAgdmFyIG1hcHBpbmdzID0gdXRpbC5nZXRBcmcoc291cmNlTWFwLCAnbWFwcGluZ3MnKTtcbiAgdmFyIGZpbGUgPSB1dGlsLmdldEFyZyhzb3VyY2VNYXAsICdmaWxlJywgbnVsbCk7XG5cbiAgLy8gT25jZSBhZ2FpbiwgU2FzcyBkZXZpYXRlcyBmcm9tIHRoZSBzcGVjIGFuZCBzdXBwbGllcyB0aGUgdmVyc2lvbiBhcyBhXG4gIC8vIHN0cmluZyByYXRoZXIgdGhhbiBhIG51bWJlciwgc28gd2UgdXNlIGxvb3NlIGVxdWFsaXR5IGNoZWNraW5nIGhlcmUuXG4gIGlmICh2ZXJzaW9uICE9IHRoaXMuX3ZlcnNpb24pIHtcbiAgICB0aHJvdyBuZXcgRXJyb3IoJ1Vuc3VwcG9ydGVkIHZlcnNpb246ICcgKyB2ZXJzaW9uKTtcbiAgfVxuXG4gIGlmIChzb3VyY2VSb290KSB7XG4gICAgc291cmNlUm9vdCA9IHV0aWwubm9ybWFsaXplKHNvdXJjZVJvb3QpO1xuICB9XG5cbiAgc291cmNlcyA9IHNvdXJjZXNcbiAgICAubWFwKFN0cmluZylcbiAgICAvLyBTb21lIHNvdXJjZSBtYXBzIHByb2R1Y2UgcmVsYXRpdmUgc291cmNlIHBhdGhzIGxpa2UgXCIuL2Zvby5qc1wiIGluc3RlYWQgb2ZcbiAgICAvLyBcImZvby5qc1wiLiAgTm9ybWFsaXplIHRoZXNlIGZpcnN0IHNvIHRoYXQgZnV0dXJlIGNvbXBhcmlzb25zIHdpbGwgc3VjY2VlZC5cbiAgICAvLyBTZWUgYnVnemlsLmxhLzEwOTA3NjguXG4gICAgLm1hcCh1dGlsLm5vcm1hbGl6ZSlcbiAgICAvLyBBbHdheXMgZW5zdXJlIHRoYXQgYWJzb2x1dGUgc291cmNlcyBhcmUgaW50ZXJuYWxseSBzdG9yZWQgcmVsYXRpdmUgdG9cbiAgICAvLyB0aGUgc291cmNlIHJvb3QsIGlmIHRoZSBzb3VyY2Ugcm9vdCBpcyBhYnNvbHV0ZS4gTm90IGRvaW5nIHRoaXMgd291bGRcbiAgICAvLyBiZSBwYXJ0aWN1bGFybHkgcHJvYmxlbWF0aWMgd2hlbiB0aGUgc291cmNlIHJvb3QgaXMgYSBwcmVmaXggb2YgdGhlXG4gICAgLy8gc291cmNlICh2YWxpZCwgYnV0IHdoeT8/KS4gU2VlIGdpdGh1YiBpc3N1ZSAjMTk5IGFuZCBidWd6aWwubGEvMTE4ODk4Mi5cbiAgICAubWFwKGZ1bmN0aW9uIChzb3VyY2UpIHtcbiAgICAgIHJldHVybiBzb3VyY2VSb290ICYmIHV0aWwuaXNBYnNvbHV0ZShzb3VyY2VSb290KSAmJiB1dGlsLmlzQWJzb2x1dGUoc291cmNlKVxuICAgICAgICA/IHV0aWwucmVsYXRpdmUoc291cmNlUm9vdCwgc291cmNlKVxuICAgICAgICA6IHNvdXJjZTtcbiAgICB9KTtcblxuICAvLyBQYXNzIGB0cnVlYCBiZWxvdyB0byBhbGxvdyBkdXBsaWNhdGUgbmFtZXMgYW5kIHNvdXJjZXMuIFdoaWxlIHNvdXJjZSBtYXBzXG4gIC8vIGFyZSBpbnRlbmRlZCB0byBiZSBjb21wcmVzc2VkIGFuZCBkZWR1cGxpY2F0ZWQsIHRoZSBUeXBlU2NyaXB0IGNvbXBpbGVyXG4gIC8vIHNvbWV0aW1lcyBnZW5lcmF0ZXMgc291cmNlIG1hcHMgd2l0aCBkdXBsaWNhdGVzIGluIHRoZW0uIFNlZSBHaXRodWIgaXNzdWVcbiAgLy8gIzcyIGFuZCBidWd6aWwubGEvODg5NDkyLlxuICB0aGlzLl9uYW1lcyA9IEFycmF5U2V0LmZyb21BcnJheShuYW1lcy5tYXAoU3RyaW5nKSwgdHJ1ZSk7XG4gIHRoaXMuX3NvdXJjZXMgPSBBcnJheVNldC5mcm9tQXJyYXkoc291cmNlcywgdHJ1ZSk7XG5cbiAgdGhpcy5fYWJzb2x1dGVTb3VyY2VzID0gdGhpcy5fc291cmNlcy50b0FycmF5KCkubWFwKGZ1bmN0aW9uIChzKSB7XG4gICAgcmV0dXJuIHV0aWwuY29tcHV0ZVNvdXJjZVVSTChzb3VyY2VSb290LCBzLCBhU291cmNlTWFwVVJMKTtcbiAgfSk7XG5cbiAgdGhpcy5zb3VyY2VSb290ID0gc291cmNlUm9vdDtcbiAgdGhpcy5zb3VyY2VzQ29udGVudCA9IHNvdXJjZXNDb250ZW50O1xuICB0aGlzLl9tYXBwaW5ncyA9IG1hcHBpbmdzO1xuICB0aGlzLl9zb3VyY2VNYXBVUkwgPSBhU291cmNlTWFwVVJMO1xuICB0aGlzLmZpbGUgPSBmaWxlO1xufVxuXG5CYXNpY1NvdXJjZU1hcENvbnN1bWVyLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoU291cmNlTWFwQ29uc3VtZXIucHJvdG90eXBlKTtcbkJhc2ljU291cmNlTWFwQ29uc3VtZXIucHJvdG90eXBlLmNvbnN1bWVyID0gU291cmNlTWFwQ29uc3VtZXI7XG5cbi8qKlxuICogVXRpbGl0eSBmdW5jdGlvbiB0byBmaW5kIHRoZSBpbmRleCBvZiBhIHNvdXJjZS4gIFJldHVybnMgLTEgaWYgbm90XG4gKiBmb3VuZC5cbiAqL1xuQmFzaWNTb3VyY2VNYXBDb25zdW1lci5wcm90b3R5cGUuX2ZpbmRTb3VyY2VJbmRleCA9IGZ1bmN0aW9uKGFTb3VyY2UpIHtcbiAgdmFyIHJlbGF0aXZlU291cmNlID0gYVNvdXJjZTtcbiAgaWYgKHRoaXMuc291cmNlUm9vdCAhPSBudWxsKSB7XG4gICAgcmVsYXRpdmVTb3VyY2UgPSB1dGlsLnJlbGF0aXZlKHRoaXMuc291cmNlUm9vdCwgcmVsYXRpdmVTb3VyY2UpO1xuICB9XG5cbiAgaWYgKHRoaXMuX3NvdXJjZXMuaGFzKHJlbGF0aXZlU291cmNlKSkge1xuICAgIHJldHVybiB0aGlzLl9zb3VyY2VzLmluZGV4T2YocmVsYXRpdmVTb3VyY2UpO1xuICB9XG5cbiAgLy8gTWF5YmUgYVNvdXJjZSBpcyBhbiBhYnNvbHV0ZSBVUkwgYXMgcmV0dXJuZWQgYnkgfHNvdXJjZXN8LiAgSW5cbiAgLy8gdGhpcyBjYXNlIHdlIGNhbid0IHNpbXBseSB1bmRvIHRoZSB0cmFuc2Zvcm0uXG4gIHZhciBpO1xuICBmb3IgKGkgPSAwOyBpIDwgdGhpcy5fYWJzb2x1dGVTb3VyY2VzLmxlbmd0aDsgKytpKSB7XG4gICAgaWYgKHRoaXMuX2Fic29sdXRlU291cmNlc1tpXSA9PSBhU291cmNlKSB7XG4gICAgICByZXR1cm4gaTtcbiAgICB9XG4gIH1cblxuICByZXR1cm4gLTE7XG59O1xuXG4vKipcbiAqIENyZWF0ZSBhIEJhc2ljU291cmNlTWFwQ29uc3VtZXIgZnJvbSBhIFNvdXJjZU1hcEdlbmVyYXRvci5cbiAqXG4gKiBAcGFyYW0gU291cmNlTWFwR2VuZXJhdG9yIGFTb3VyY2VNYXBcbiAqICAgICAgICBUaGUgc291cmNlIG1hcCB0aGF0IHdpbGwgYmUgY29uc3VtZWQuXG4gKiBAcGFyYW0gU3RyaW5nIGFTb3VyY2VNYXBVUkxcbiAqICAgICAgICBUaGUgVVJMIGF0IHdoaWNoIHRoZSBzb3VyY2UgbWFwIGNhbiBiZSBmb3VuZCAob3B0aW9uYWwpXG4gKiBAcmV0dXJucyBCYXNpY1NvdXJjZU1hcENvbnN1bWVyXG4gKi9cbkJhc2ljU291cmNlTWFwQ29uc3VtZXIuZnJvbVNvdXJjZU1hcCA9XG4gIGZ1bmN0aW9uIFNvdXJjZU1hcENvbnN1bWVyX2Zyb21Tb3VyY2VNYXAoYVNvdXJjZU1hcCwgYVNvdXJjZU1hcFVSTCkge1xuICAgIHZhciBzbWMgPSBPYmplY3QuY3JlYXRlKEJhc2ljU291cmNlTWFwQ29uc3VtZXIucHJvdG90eXBlKTtcblxuICAgIHZhciBuYW1lcyA9IHNtYy5fbmFtZXMgPSBBcnJheVNldC5mcm9tQXJyYXkoYVNvdXJjZU1hcC5fbmFtZXMudG9BcnJheSgpLCB0cnVlKTtcbiAgICB2YXIgc291cmNlcyA9IHNtYy5fc291cmNlcyA9IEFycmF5U2V0LmZyb21BcnJheShhU291cmNlTWFwLl9zb3VyY2VzLnRvQXJyYXkoKSwgdHJ1ZSk7XG4gICAgc21jLnNvdXJjZVJvb3QgPSBhU291cmNlTWFwLl9zb3VyY2VSb290O1xuICAgIHNtYy5zb3VyY2VzQ29udGVudCA9IGFTb3VyY2VNYXAuX2dlbmVyYXRlU291cmNlc0NvbnRlbnQoc21jLl9zb3VyY2VzLnRvQXJyYXkoKSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNtYy5zb3VyY2VSb290KTtcbiAgICBzbWMuZmlsZSA9IGFTb3VyY2VNYXAuX2ZpbGU7XG4gICAgc21jLl9zb3VyY2VNYXBVUkwgPSBhU291cmNlTWFwVVJMO1xuICAgIHNtYy5fYWJzb2x1dGVTb3VyY2VzID0gc21jLl9zb3VyY2VzLnRvQXJyYXkoKS5tYXAoZnVuY3Rpb24gKHMpIHtcbiAgICAgIHJldHVybiB1dGlsLmNvbXB1dGVTb3VyY2VVUkwoc21jLnNvdXJjZVJvb3QsIHMsIGFTb3VyY2VNYXBVUkwpO1xuICAgIH0pO1xuXG4gICAgLy8gQmVjYXVzZSB3ZSBhcmUgbW9kaWZ5aW5nIHRoZSBlbnRyaWVzIChieSBjb252ZXJ0aW5nIHN0cmluZyBzb3VyY2VzIGFuZFxuICAgIC8vIG5hbWVzIHRvIGluZGljZXMgaW50byB0aGUgc291cmNlcyBhbmQgbmFtZXMgQXJyYXlTZXRzKSwgd2UgaGF2ZSB0byBtYWtlXG4gICAgLy8gYSBjb3B5IG9mIHRoZSBlbnRyeSBvciBlbHNlIGJhZCB0aGluZ3MgaGFwcGVuLiBTaGFyZWQgbXV0YWJsZSBzdGF0ZVxuICAgIC8vIHN0cmlrZXMgYWdhaW4hIFNlZSBnaXRodWIgaXNzdWUgIzE5MS5cblxuICAgIHZhciBnZW5lcmF0ZWRNYXBwaW5ncyA9IGFTb3VyY2VNYXAuX21hcHBpbmdzLnRvQXJyYXkoKS5zbGljZSgpO1xuICAgIHZhciBkZXN0R2VuZXJhdGVkTWFwcGluZ3MgPSBzbWMuX19nZW5lcmF0ZWRNYXBwaW5ncyA9IFtdO1xuICAgIHZhciBkZXN0T3JpZ2luYWxNYXBwaW5ncyA9IHNtYy5fX29yaWdpbmFsTWFwcGluZ3MgPSBbXTtcblxuICAgIGZvciAodmFyIGkgPSAwLCBsZW5ndGggPSBnZW5lcmF0ZWRNYXBwaW5ncy5sZW5ndGg7IGkgPCBsZW5ndGg7IGkrKykge1xuICAgICAgdmFyIHNyY01hcHBpbmcgPSBnZW5lcmF0ZWRNYXBwaW5nc1tpXTtcbiAgICAgIHZhciBkZXN0TWFwcGluZyA9IG5ldyBNYXBwaW5nO1xuICAgICAgZGVzdE1hcHBpbmcuZ2VuZXJhdGVkTGluZSA9IHNyY01hcHBpbmcuZ2VuZXJhdGVkTGluZTtcbiAgICAgIGRlc3RNYXBwaW5nLmdlbmVyYXRlZENvbHVtbiA9IHNyY01hcHBpbmcuZ2VuZXJhdGVkQ29sdW1uO1xuXG4gICAgICBpZiAoc3JjTWFwcGluZy5zb3VyY2UpIHtcbiAgICAgICAgZGVzdE1hcHBpbmcuc291cmNlID0gc291cmNlcy5pbmRleE9mKHNyY01hcHBpbmcuc291cmNlKTtcbiAgICAgICAgZGVzdE1hcHBpbmcub3JpZ2luYWxMaW5lID0gc3JjTWFwcGluZy5vcmlnaW5hbExpbmU7XG4gICAgICAgIGRlc3RNYXBwaW5nLm9yaWdpbmFsQ29sdW1uID0gc3JjTWFwcGluZy5vcmlnaW5hbENvbHVtbjtcblxuICAgICAgICBpZiAoc3JjTWFwcGluZy5uYW1lKSB7XG4gICAgICAgICAgZGVzdE1hcHBpbmcubmFtZSA9IG5hbWVzLmluZGV4T2Yoc3JjTWFwcGluZy5uYW1lKTtcbiAgICAgICAgfVxuXG4gICAgICAgIGRlc3RPcmlnaW5hbE1hcHBpbmdzLnB1c2goZGVzdE1hcHBpbmcpO1xuICAgICAgfVxuXG4gICAgICBkZXN0R2VuZXJhdGVkTWFwcGluZ3MucHVzaChkZXN0TWFwcGluZyk7XG4gICAgfVxuXG4gICAgcXVpY2tTb3J0KHNtYy5fX29yaWdpbmFsTWFwcGluZ3MsIHV0aWwuY29tcGFyZUJ5T3JpZ2luYWxQb3NpdGlvbnMpO1xuXG4gICAgcmV0dXJuIHNtYztcbiAgfTtcblxuLyoqXG4gKiBUaGUgdmVyc2lvbiBvZiB0aGUgc291cmNlIG1hcHBpbmcgc3BlYyB0aGF0IHdlIGFyZSBjb25zdW1pbmcuXG4gKi9cbkJhc2ljU291cmNlTWFwQ29uc3VtZXIucHJvdG90eXBlLl92ZXJzaW9uID0gMztcblxuLyoqXG4gKiBUaGUgbGlzdCBvZiBvcmlnaW5hbCBzb3VyY2VzLlxuICovXG5PYmplY3QuZGVmaW5lUHJvcGVydHkoQmFzaWNTb3VyY2VNYXBDb25zdW1lci5wcm90b3R5cGUsICdzb3VyY2VzJywge1xuICBnZXQ6IGZ1bmN0aW9uICgpIHtcbiAgICByZXR1cm4gdGhpcy5fYWJzb2x1dGVTb3VyY2VzLnNsaWNlKCk7XG4gIH1cbn0pO1xuXG4vKipcbiAqIFByb3ZpZGUgdGhlIEpJVCB3aXRoIGEgbmljZSBzaGFwZSAvIGhpZGRlbiBjbGFzcy5cbiAqL1xuZnVuY3Rpb24gTWFwcGluZygpIHtcbiAgdGhpcy5nZW5lcmF0ZWRMaW5lID0gMDtcbiAgdGhpcy5nZW5lcmF0ZWRDb2x1bW4gPSAwO1xuICB0aGlzLnNvdXJjZSA9IG51bGw7XG4gIHRoaXMub3JpZ2luYWxMaW5lID0gbnVsbDtcbiAgdGhpcy5vcmlnaW5hbENvbHVtbiA9IG51bGw7XG4gIHRoaXMubmFtZSA9IG51bGw7XG59XG5cbi8qKlxuICogUGFyc2UgdGhlIG1hcHBpbmdzIGluIGEgc3RyaW5nIGluIHRvIGEgZGF0YSBzdHJ1Y3R1cmUgd2hpY2ggd2UgY2FuIGVhc2lseVxuICogcXVlcnkgKHRoZSBvcmRlcmVkIGFycmF5cyBpbiB0aGUgYHRoaXMuX19nZW5lcmF0ZWRNYXBwaW5nc2AgYW5kXG4gKiBgdGhpcy5fX29yaWdpbmFsTWFwcGluZ3NgIHByb3BlcnRpZXMpLlxuICovXG5cbmNvbnN0IGNvbXBhcmVHZW5lcmF0ZWQgPSB1dGlsLmNvbXBhcmVCeUdlbmVyYXRlZFBvc2l0aW9uc0RlZmxhdGVkTm9MaW5lO1xuZnVuY3Rpb24gc29ydEdlbmVyYXRlZChhcnJheSwgc3RhcnQpIHtcbiAgbGV0IGwgPSBhcnJheS5sZW5ndGg7XG4gIGxldCBuID0gYXJyYXkubGVuZ3RoIC0gc3RhcnQ7XG4gIGlmIChuIDw9IDEpIHtcbiAgICByZXR1cm47XG4gIH0gZWxzZSBpZiAobiA9PSAyKSB7XG4gICAgbGV0IGEgPSBhcnJheVtzdGFydF07XG4gICAgbGV0IGIgPSBhcnJheVtzdGFydCArIDFdO1xuICAgIGlmIChjb21wYXJlR2VuZXJhdGVkKGEsIGIpID4gMCkge1xuICAgICAgYXJyYXlbc3RhcnRdID0gYjtcbiAgICAgIGFycmF5W3N0YXJ0ICsgMV0gPSBhO1xuICAgIH1cbiAgfSBlbHNlIGlmIChuIDwgMjApIHtcbiAgICBmb3IgKGxldCBpID0gc3RhcnQ7IGkgPCBsOyBpKyspIHtcbiAgICAgIGZvciAobGV0IGogPSBpOyBqID4gc3RhcnQ7IGotLSkge1xuICAgICAgICBsZXQgYSA9IGFycmF5W2ogLSAxXTtcbiAgICAgICAgbGV0IGIgPSBhcnJheVtqXTtcbiAgICAgICAgaWYgKGNvbXBhcmVHZW5lcmF0ZWQoYSwgYikgPD0gMCkge1xuICAgICAgICAgIGJyZWFrO1xuICAgICAgICB9XG4gICAgICAgIGFycmF5W2ogLSAxXSA9IGI7XG4gICAgICAgIGFycmF5W2pdID0gYTtcbiAgICAgIH1cbiAgICB9XG4gIH0gZWxzZSB7XG4gICAgcXVpY2tTb3J0KGFycmF5LCBjb21wYXJlR2VuZXJhdGVkLCBzdGFydCk7XG4gIH1cbn1cbkJhc2ljU291cmNlTWFwQ29uc3VtZXIucHJvdG90eXBlLl9wYXJzZU1hcHBpbmdzID1cbiAgZnVuY3Rpb24gU291cmNlTWFwQ29uc3VtZXJfcGFyc2VNYXBwaW5ncyhhU3RyLCBhU291cmNlUm9vdCkge1xuICAgIHZhciBnZW5lcmF0ZWRMaW5lID0gMTtcbiAgICB2YXIgcHJldmlvdXNHZW5lcmF0ZWRDb2x1bW4gPSAwO1xuICAgIHZhciBwcmV2aW91c09yaWdpbmFsTGluZSA9IDA7XG4gICAgdmFyIHByZXZpb3VzT3JpZ2luYWxDb2x1bW4gPSAwO1xuICAgIHZhciBwcmV2aW91c1NvdXJjZSA9IDA7XG4gICAgdmFyIHByZXZpb3VzTmFtZSA9IDA7XG4gICAgdmFyIGxlbmd0aCA9IGFTdHIubGVuZ3RoO1xuICAgIHZhciBpbmRleCA9IDA7XG4gICAgdmFyIGNhY2hlZFNlZ21lbnRzID0ge307XG4gICAgdmFyIHRlbXAgPSB7fTtcbiAgICB2YXIgb3JpZ2luYWxNYXBwaW5ncyA9IFtdO1xuICAgIHZhciBnZW5lcmF0ZWRNYXBwaW5ncyA9IFtdO1xuICAgIHZhciBtYXBwaW5nLCBzdHIsIHNlZ21lbnQsIGVuZCwgdmFsdWU7XG5cbiAgICBsZXQgc3ViYXJyYXlTdGFydCA9IDA7XG4gICAgd2hpbGUgKGluZGV4IDwgbGVuZ3RoKSB7XG4gICAgICBpZiAoYVN0ci5jaGFyQXQoaW5kZXgpID09PSAnOycpIHtcbiAgICAgICAgZ2VuZXJhdGVkTGluZSsrO1xuICAgICAgICBpbmRleCsrO1xuICAgICAgICBwcmV2aW91c0dlbmVyYXRlZENvbHVtbiA9IDA7XG5cbiAgICAgICAgc29ydEdlbmVyYXRlZChnZW5lcmF0ZWRNYXBwaW5ncywgc3ViYXJyYXlTdGFydCk7XG4gICAgICAgIHN1YmFycmF5U3RhcnQgPSBnZW5lcmF0ZWRNYXBwaW5ncy5sZW5ndGg7XG4gICAgICB9XG4gICAgICBlbHNlIGlmIChhU3RyLmNoYXJBdChpbmRleCkgPT09ICcsJykge1xuICAgICAgICBpbmRleCsrO1xuICAgICAgfVxuICAgICAgZWxzZSB7XG4gICAgICAgIG1hcHBpbmcgPSBuZXcgTWFwcGluZygpO1xuICAgICAgICBtYXBwaW5nLmdlbmVyYXRlZExpbmUgPSBnZW5lcmF0ZWRMaW5lO1xuXG4gICAgICAgIGZvciAoZW5kID0gaW5kZXg7IGVuZCA8IGxlbmd0aDsgZW5kKyspIHtcbiAgICAgICAgICBpZiAodGhpcy5fY2hhcklzTWFwcGluZ1NlcGFyYXRvcihhU3RyLCBlbmQpKSB7XG4gICAgICAgICAgICBicmVhaztcbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgICAgc3RyID0gYVN0ci5zbGljZShpbmRleCwgZW5kKTtcblxuICAgICAgICBzZWdtZW50ID0gW107XG4gICAgICAgIHdoaWxlIChpbmRleCA8IGVuZCkge1xuICAgICAgICAgIGJhc2U2NFZMUS5kZWNvZGUoYVN0ciwgaW5kZXgsIHRlbXApO1xuICAgICAgICAgIHZhbHVlID0gdGVtcC52YWx1ZTtcbiAgICAgICAgICBpbmRleCA9IHRlbXAucmVzdDtcbiAgICAgICAgICBzZWdtZW50LnB1c2godmFsdWUpO1xuICAgICAgICB9XG5cbiAgICAgICAgaWYgKHNlZ21lbnQubGVuZ3RoID09PSAyKSB7XG4gICAgICAgICAgdGhyb3cgbmV3IEVycm9yKCdGb3VuZCBhIHNvdXJjZSwgYnV0IG5vIGxpbmUgYW5kIGNvbHVtbicpO1xuICAgICAgICB9XG5cbiAgICAgICAgaWYgKHNlZ21lbnQubGVuZ3RoID09PSAzKSB7XG4gICAgICAgICAgdGhyb3cgbmV3IEVycm9yKCdGb3VuZCBhIHNvdXJjZSBhbmQgbGluZSwgYnV0IG5vIGNvbHVtbicpO1xuICAgICAgICB9XG5cbiAgICAgICAgLy8gR2VuZXJhdGVkIGNvbHVtbi5cbiAgICAgICAgbWFwcGluZy5nZW5lcmF0ZWRDb2x1bW4gPSBwcmV2aW91c0dlbmVyYXRlZENvbHVtbiArIHNlZ21lbnRbMF07XG4gICAgICAgIHByZXZpb3VzR2VuZXJhdGVkQ29sdW1uID0gbWFwcGluZy5nZW5lcmF0ZWRDb2x1bW47XG5cbiAgICAgICAgaWYgKHNlZ21lbnQubGVuZ3RoID4gMSkge1xuICAgICAgICAgIC8vIE9yaWdpbmFsIHNvdXJjZS5cbiAgICAgICAgICBtYXBwaW5nLnNvdXJjZSA9IHByZXZpb3VzU291cmNlICsgc2VnbWVudFsxXTtcbiAgICAgICAgICBwcmV2aW91c1NvdXJjZSArPSBzZWdtZW50WzFdO1xuXG4gICAgICAgICAgLy8gT3JpZ2luYWwgbGluZS5cbiAgICAgICAgICBtYXBwaW5nLm9yaWdpbmFsTGluZSA9IHByZXZpb3VzT3JpZ2luYWxMaW5lICsgc2VnbWVudFsyXTtcbiAgICAgICAgICBwcmV2aW91c09yaWdpbmFsTGluZSA9IG1hcHBpbmcub3JpZ2luYWxMaW5lO1xuICAgICAgICAgIC8vIExpbmVzIGFyZSBzdG9yZWQgMC1iYXNlZFxuICAgICAgICAgIG1hcHBpbmcub3JpZ2luYWxMaW5lICs9IDE7XG5cbiAgICAgICAgICAvLyBPcmlnaW5hbCBjb2x1bW4uXG4gICAgICAgICAgbWFwcGluZy5vcmlnaW5hbENvbHVtbiA9IHByZXZpb3VzT3JpZ2luYWxDb2x1bW4gKyBzZWdtZW50WzNdO1xuICAgICAgICAgIHByZXZpb3VzT3JpZ2luYWxDb2x1bW4gPSBtYXBwaW5nLm9yaWdpbmFsQ29sdW1uO1xuXG4gICAgICAgICAgaWYgKHNlZ21lbnQubGVuZ3RoID4gNCkge1xuICAgICAgICAgICAgLy8gT3JpZ2luYWwgbmFtZS5cbiAgICAgICAgICAgIG1hcHBpbmcubmFtZSA9IHByZXZpb3VzTmFtZSArIHNlZ21lbnRbNF07XG4gICAgICAgICAgICBwcmV2aW91c05hbWUgKz0gc2VnbWVudFs0XTtcbiAgICAgICAgICB9XG4gICAgICAgIH1cblxuICAgICAgICBnZW5lcmF0ZWRNYXBwaW5ncy5wdXNoKG1hcHBpbmcpO1xuICAgICAgICBpZiAodHlwZW9mIG1hcHBpbmcub3JpZ2luYWxMaW5lID09PSAnbnVtYmVyJykge1xuICAgICAgICAgIGxldCBjdXJyZW50U291cmNlID0gbWFwcGluZy5zb3VyY2U7XG4gICAgICAgICAgd2hpbGUgKG9yaWdpbmFsTWFwcGluZ3MubGVuZ3RoIDw9IGN1cnJlbnRTb3VyY2UpIHtcbiAgICAgICAgICAgIG9yaWdpbmFsTWFwcGluZ3MucHVzaChudWxsKTtcbiAgICAgICAgICB9XG4gICAgICAgICAgaWYgKG9yaWdpbmFsTWFwcGluZ3NbY3VycmVudFNvdXJjZV0gPT09IG51bGwpIHtcbiAgICAgICAgICAgIG9yaWdpbmFsTWFwcGluZ3NbY3VycmVudFNvdXJjZV0gPSBbXTtcbiAgICAgICAgICB9XG4gICAgICAgICAgb3JpZ2luYWxNYXBwaW5nc1tjdXJyZW50U291cmNlXS5wdXNoKG1hcHBpbmcpO1xuICAgICAgICB9XG4gICAgICB9XG4gICAgfVxuXG4gICAgc29ydEdlbmVyYXRlZChnZW5lcmF0ZWRNYXBwaW5ncywgc3ViYXJyYXlTdGFydCk7XG4gICAgdGhpcy5fX2dlbmVyYXRlZE1hcHBpbmdzID0gZ2VuZXJhdGVkTWFwcGluZ3M7XG5cbiAgICBmb3IgKHZhciBpID0gMDsgaSA8IG9yaWdpbmFsTWFwcGluZ3MubGVuZ3RoOyBpKyspIHtcbiAgICAgIGlmIChvcmlnaW5hbE1hcHBpbmdzW2ldICE9IG51bGwpIHtcbiAgICAgICAgcXVpY2tTb3J0KG9yaWdpbmFsTWFwcGluZ3NbaV0sIHV0aWwuY29tcGFyZUJ5T3JpZ2luYWxQb3NpdGlvbnNOb1NvdXJjZSk7XG4gICAgICB9XG4gICAgfVxuICAgIHRoaXMuX19vcmlnaW5hbE1hcHBpbmdzID0gW10uY29uY2F0KC4uLm9yaWdpbmFsTWFwcGluZ3MpO1xuICB9O1xuXG4vKipcbiAqIEZpbmQgdGhlIG1hcHBpbmcgdGhhdCBiZXN0IG1hdGNoZXMgdGhlIGh5cG90aGV0aWNhbCBcIm5lZWRsZVwiIG1hcHBpbmcgdGhhdFxuICogd2UgYXJlIHNlYXJjaGluZyBmb3IgaW4gdGhlIGdpdmVuIFwiaGF5c3RhY2tcIiBvZiBtYXBwaW5ncy5cbiAqL1xuQmFzaWNTb3VyY2VNYXBDb25zdW1lci5wcm90b3R5cGUuX2ZpbmRNYXBwaW5nID1cbiAgZnVuY3Rpb24gU291cmNlTWFwQ29uc3VtZXJfZmluZE1hcHBpbmcoYU5lZWRsZSwgYU1hcHBpbmdzLCBhTGluZU5hbWUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGFDb2x1bW5OYW1lLCBhQ29tcGFyYXRvciwgYUJpYXMpIHtcbiAgICAvLyBUbyByZXR1cm4gdGhlIHBvc2l0aW9uIHdlIGFyZSBzZWFyY2hpbmcgZm9yLCB3ZSBtdXN0IGZpcnN0IGZpbmQgdGhlXG4gICAgLy8gbWFwcGluZyBmb3IgdGhlIGdpdmVuIHBvc2l0aW9uIGFuZCB0aGVuIHJldHVybiB0aGUgb3Bwb3NpdGUgcG9zaXRpb24gaXRcbiAgICAvLyBwb2ludHMgdG8uIEJlY2F1c2UgdGhlIG1hcHBpbmdzIGFyZSBzb3J0ZWQsIHdlIGNhbiB1c2UgYmluYXJ5IHNlYXJjaCB0b1xuICAgIC8vIGZpbmQgdGhlIGJlc3QgbWFwcGluZy5cblxuICAgIGlmIChhTmVlZGxlW2FMaW5lTmFtZV0gPD0gMCkge1xuICAgICAgdGhyb3cgbmV3IFR5cGVFcnJvcignTGluZSBtdXN0IGJlIGdyZWF0ZXIgdGhhbiBvciBlcXVhbCB0byAxLCBnb3QgJ1xuICAgICAgICAgICAgICAgICAgICAgICAgICArIGFOZWVkbGVbYUxpbmVOYW1lXSk7XG4gICAgfVxuICAgIGlmIChhTmVlZGxlW2FDb2x1bW5OYW1lXSA8IDApIHtcbiAgICAgIHRocm93IG5ldyBUeXBlRXJyb3IoJ0NvbHVtbiBtdXN0IGJlIGdyZWF0ZXIgdGhhbiBvciBlcXVhbCB0byAwLCBnb3QgJ1xuICAgICAgICAgICAgICAgICAgICAgICAgICArIGFOZWVkbGVbYUNvbHVtbk5hbWVdKTtcbiAgICB9XG5cbiAgICByZXR1cm4gYmluYXJ5U2VhcmNoLnNlYXJjaChhTmVlZGxlLCBhTWFwcGluZ3MsIGFDb21wYXJhdG9yLCBhQmlhcyk7XG4gIH07XG5cbi8qKlxuICogQ29tcHV0ZSB0aGUgbGFzdCBjb2x1bW4gZm9yIGVhY2ggZ2VuZXJhdGVkIG1hcHBpbmcuIFRoZSBsYXN0IGNvbHVtbiBpc1xuICogaW5jbHVzaXZlLlxuICovXG5CYXNpY1NvdXJjZU1hcENvbnN1bWVyLnByb3RvdHlwZS5jb21wdXRlQ29sdW1uU3BhbnMgPVxuICBmdW5jdGlvbiBTb3VyY2VNYXBDb25zdW1lcl9jb21wdXRlQ29sdW1uU3BhbnMoKSB7XG4gICAgZm9yICh2YXIgaW5kZXggPSAwOyBpbmRleCA8IHRoaXMuX2dlbmVyYXRlZE1hcHBpbmdzLmxlbmd0aDsgKytpbmRleCkge1xuICAgICAgdmFyIG1hcHBpbmcgPSB0aGlzLl9nZW5lcmF0ZWRNYXBwaW5nc1tpbmRleF07XG5cbiAgICAgIC8vIE1hcHBpbmdzIGRvIG5vdCBjb250YWluIGEgZmllbGQgZm9yIHRoZSBsYXN0IGdlbmVyYXRlZCBjb2x1bW50LiBXZVxuICAgICAgLy8gY2FuIGNvbWUgdXAgd2l0aCBhbiBvcHRpbWlzdGljIGVzdGltYXRlLCBob3dldmVyLCBieSBhc3N1bWluZyB0aGF0XG4gICAgICAvLyBtYXBwaW5ncyBhcmUgY29udGlndW91cyAoaS5lLiBnaXZlbiB0d28gY29uc2VjdXRpdmUgbWFwcGluZ3MsIHRoZVxuICAgICAgLy8gZmlyc3QgbWFwcGluZyBlbmRzIHdoZXJlIHRoZSBzZWNvbmQgb25lIHN0YXJ0cykuXG4gICAgICBpZiAoaW5kZXggKyAxIDwgdGhpcy5fZ2VuZXJhdGVkTWFwcGluZ3MubGVuZ3RoKSB7XG4gICAgICAgIHZhciBuZXh0TWFwcGluZyA9IHRoaXMuX2dlbmVyYXRlZE1hcHBpbmdzW2luZGV4ICsgMV07XG5cbiAgICAgICAgaWYgKG1hcHBpbmcuZ2VuZXJhdGVkTGluZSA9PT0gbmV4dE1hcHBpbmcuZ2VuZXJhdGVkTGluZSkge1xuICAgICAgICAgIG1hcHBpbmcubGFzdEdlbmVyYXRlZENvbHVtbiA9IG5leHRNYXBwaW5nLmdlbmVyYXRlZENvbHVtbiAtIDE7XG4gICAgICAgICAgY29udGludWU7XG4gICAgICAgIH1cbiAgICAgIH1cblxuICAgICAgLy8gVGhlIGxhc3QgbWFwcGluZyBmb3IgZWFjaCBsaW5lIHNwYW5zIHRoZSBlbnRpcmUgbGluZS5cbiAgICAgIG1hcHBpbmcubGFzdEdlbmVyYXRlZENvbHVtbiA9IEluZmluaXR5O1xuICAgIH1cbiAgfTtcblxuLyoqXG4gKiBSZXR1cm5zIHRoZSBvcmlnaW5hbCBzb3VyY2UsIGxpbmUsIGFuZCBjb2x1bW4gaW5mb3JtYXRpb24gZm9yIHRoZSBnZW5lcmF0ZWRcbiAqIHNvdXJjZSdzIGxpbmUgYW5kIGNvbHVtbiBwb3NpdGlvbnMgcHJvdmlkZWQuIFRoZSBvbmx5IGFyZ3VtZW50IGlzIGFuIG9iamVjdFxuICogd2l0aCB0aGUgZm9sbG93aW5nIHByb3BlcnRpZXM6XG4gKlxuICogICAtIGxpbmU6IFRoZSBsaW5lIG51bWJlciBpbiB0aGUgZ2VuZXJhdGVkIHNvdXJjZS4gIFRoZSBsaW5lIG51bWJlclxuICogICAgIGlzIDEtYmFzZWQuXG4gKiAgIC0gY29sdW1uOiBUaGUgY29sdW1uIG51bWJlciBpbiB0aGUgZ2VuZXJhdGVkIHNvdXJjZS4gIFRoZSBjb2x1bW5cbiAqICAgICBudW1iZXIgaXMgMC1iYXNlZC5cbiAqICAgLSBiaWFzOiBFaXRoZXIgJ1NvdXJjZU1hcENvbnN1bWVyLkdSRUFURVNUX0xPV0VSX0JPVU5EJyBvclxuICogICAgICdTb3VyY2VNYXBDb25zdW1lci5MRUFTVF9VUFBFUl9CT1VORCcuIFNwZWNpZmllcyB3aGV0aGVyIHRvIHJldHVybiB0aGVcbiAqICAgICBjbG9zZXN0IGVsZW1lbnQgdGhhdCBpcyBzbWFsbGVyIHRoYW4gb3IgZ3JlYXRlciB0aGFuIHRoZSBvbmUgd2UgYXJlXG4gKiAgICAgc2VhcmNoaW5nIGZvciwgcmVzcGVjdGl2ZWx5LCBpZiB0aGUgZXhhY3QgZWxlbWVudCBjYW5ub3QgYmUgZm91bmQuXG4gKiAgICAgRGVmYXVsdHMgdG8gJ1NvdXJjZU1hcENvbnN1bWVyLkdSRUFURVNUX0xPV0VSX0JPVU5EJy5cbiAqXG4gKiBhbmQgYW4gb2JqZWN0IGlzIHJldHVybmVkIHdpdGggdGhlIGZvbGxvd2luZyBwcm9wZXJ0aWVzOlxuICpcbiAqICAgLSBzb3VyY2U6IFRoZSBvcmlnaW5hbCBzb3VyY2UgZmlsZSwgb3IgbnVsbC5cbiAqICAgLSBsaW5lOiBUaGUgbGluZSBudW1iZXIgaW4gdGhlIG9yaWdpbmFsIHNvdXJjZSwgb3IgbnVsbC4gIFRoZVxuICogICAgIGxpbmUgbnVtYmVyIGlzIDEtYmFzZWQuXG4gKiAgIC0gY29sdW1uOiBUaGUgY29sdW1uIG51bWJlciBpbiB0aGUgb3JpZ2luYWwgc291cmNlLCBvciBudWxsLiAgVGhlXG4gKiAgICAgY29sdW1uIG51bWJlciBpcyAwLWJhc2VkLlxuICogICAtIG5hbWU6IFRoZSBvcmlnaW5hbCBpZGVudGlmaWVyLCBvciBudWxsLlxuICovXG5CYXNpY1NvdXJjZU1hcENvbnN1bWVyLnByb3RvdHlwZS5vcmlnaW5hbFBvc2l0aW9uRm9yID1cbiAgZnVuY3Rpb24gU291cmNlTWFwQ29uc3VtZXJfb3JpZ2luYWxQb3NpdGlvbkZvcihhQXJncykge1xuICAgIHZhciBuZWVkbGUgPSB7XG4gICAgICBnZW5lcmF0ZWRMaW5lOiB1dGlsLmdldEFyZyhhQXJncywgJ2xpbmUnKSxcbiAgICAgIGdlbmVyYXRlZENvbHVtbjogdXRpbC5nZXRBcmcoYUFyZ3MsICdjb2x1bW4nKVxuICAgIH07XG5cbiAgICB2YXIgaW5kZXggPSB0aGlzLl9maW5kTWFwcGluZyhcbiAgICAgIG5lZWRsZSxcbiAgICAgIHRoaXMuX2dlbmVyYXRlZE1hcHBpbmdzLFxuICAgICAgXCJnZW5lcmF0ZWRMaW5lXCIsXG4gICAgICBcImdlbmVyYXRlZENvbHVtblwiLFxuICAgICAgdXRpbC5jb21wYXJlQnlHZW5lcmF0ZWRQb3NpdGlvbnNEZWZsYXRlZCxcbiAgICAgIHV0aWwuZ2V0QXJnKGFBcmdzLCAnYmlhcycsIFNvdXJjZU1hcENvbnN1bWVyLkdSRUFURVNUX0xPV0VSX0JPVU5EKVxuICAgICk7XG5cbiAgICBpZiAoaW5kZXggPj0gMCkge1xuICAgICAgdmFyIG1hcHBpbmcgPSB0aGlzLl9nZW5lcmF0ZWRNYXBwaW5nc1tpbmRleF07XG5cbiAgICAgIGlmIChtYXBwaW5nLmdlbmVyYXRlZExpbmUgPT09IG5lZWRsZS5nZW5lcmF0ZWRMaW5lKSB7XG4gICAgICAgIHZhciBzb3VyY2UgPSB1dGlsLmdldEFyZyhtYXBwaW5nLCAnc291cmNlJywgbnVsbCk7XG4gICAgICAgIGlmIChzb3VyY2UgIT09IG51bGwpIHtcbiAgICAgICAgICBzb3VyY2UgPSB0aGlzLl9zb3VyY2VzLmF0KHNvdXJjZSk7XG4gICAgICAgICAgc291cmNlID0gdXRpbC5jb21wdXRlU291cmNlVVJMKHRoaXMuc291cmNlUm9vdCwgc291cmNlLCB0aGlzLl9zb3VyY2VNYXBVUkwpO1xuICAgICAgICB9XG4gICAgICAgIHZhciBuYW1lID0gdXRpbC5nZXRBcmcobWFwcGluZywgJ25hbWUnLCBudWxsKTtcbiAgICAgICAgaWYgKG5hbWUgIT09IG51bGwpIHtcbiAgICAgICAgICBuYW1lID0gdGhpcy5fbmFtZXMuYXQobmFtZSk7XG4gICAgICAgIH1cbiAgICAgICAgcmV0dXJuIHtcbiAgICAgICAgICBzb3VyY2U6IHNvdXJjZSxcbiAgICAgICAgICBsaW5lOiB1dGlsLmdldEFyZyhtYXBwaW5nLCAnb3JpZ2luYWxMaW5lJywgbnVsbCksXG4gICAgICAgICAgY29sdW1uOiB1dGlsLmdldEFyZyhtYXBwaW5nLCAnb3JpZ2luYWxDb2x1bW4nLCBudWxsKSxcbiAgICAgICAgICBuYW1lOiBuYW1lXG4gICAgICAgIH07XG4gICAgICB9XG4gICAgfVxuXG4gICAgcmV0dXJuIHtcbiAgICAgIHNvdXJjZTogbnVsbCxcbiAgICAgIGxpbmU6IG51bGwsXG4gICAgICBjb2x1bW46IG51bGwsXG4gICAgICBuYW1lOiBudWxsXG4gICAgfTtcbiAgfTtcblxuLyoqXG4gKiBSZXR1cm4gdHJ1ZSBpZiB3ZSBoYXZlIHRoZSBzb3VyY2UgY29udGVudCBmb3IgZXZlcnkgc291cmNlIGluIHRoZSBzb3VyY2VcbiAqIG1hcCwgZmFsc2Ugb3RoZXJ3aXNlLlxuICovXG5CYXNpY1NvdXJjZU1hcENvbnN1bWVyLnByb3RvdHlwZS5oYXNDb250ZW50c09mQWxsU291cmNlcyA9XG4gIGZ1bmN0aW9uIEJhc2ljU291cmNlTWFwQ29uc3VtZXJfaGFzQ29udGVudHNPZkFsbFNvdXJjZXMoKSB7XG4gICAgaWYgKCF0aGlzLnNvdXJjZXNDb250ZW50KSB7XG4gICAgICByZXR1cm4gZmFsc2U7XG4gICAgfVxuICAgIHJldHVybiB0aGlzLnNvdXJjZXNDb250ZW50Lmxlbmd0aCA+PSB0aGlzLl9zb3VyY2VzLnNpemUoKSAmJlxuICAgICAgIXRoaXMuc291cmNlc0NvbnRlbnQuc29tZShmdW5jdGlvbiAoc2MpIHsgcmV0dXJuIHNjID09IG51bGw7IH0pO1xuICB9O1xuXG4vKipcbiAqIFJldHVybnMgdGhlIG9yaWdpbmFsIHNvdXJjZSBjb250ZW50LiBUaGUgb25seSBhcmd1bWVudCBpcyB0aGUgdXJsIG9mIHRoZVxuICogb3JpZ2luYWwgc291cmNlIGZpbGUuIFJldHVybnMgbnVsbCBpZiBubyBvcmlnaW5hbCBzb3VyY2UgY29udGVudCBpc1xuICogYXZhaWxhYmxlLlxuICovXG5CYXNpY1NvdXJjZU1hcENvbnN1bWVyLnByb3RvdHlwZS5zb3VyY2VDb250ZW50Rm9yID1cbiAgZnVuY3Rpb24gU291cmNlTWFwQ29uc3VtZXJfc291cmNlQ29udGVudEZvcihhU291cmNlLCBudWxsT25NaXNzaW5nKSB7XG4gICAgaWYgKCF0aGlzLnNvdXJjZXNDb250ZW50KSB7XG4gICAgICByZXR1cm4gbnVsbDtcbiAgICB9XG5cbiAgICB2YXIgaW5kZXggPSB0aGlzLl9maW5kU291cmNlSW5kZXgoYVNvdXJjZSk7XG4gICAgaWYgKGluZGV4ID49IDApIHtcbiAgICAgIHJldHVybiB0aGlzLnNvdXJjZXNDb250ZW50W2luZGV4XTtcbiAgICB9XG5cbiAgICB2YXIgcmVsYXRpdmVTb3VyY2UgPSBhU291cmNlO1xuICAgIGlmICh0aGlzLnNvdXJjZVJvb3QgIT0gbnVsbCkge1xuICAgICAgcmVsYXRpdmVTb3VyY2UgPSB1dGlsLnJlbGF0aXZlKHRoaXMuc291cmNlUm9vdCwgcmVsYXRpdmVTb3VyY2UpO1xuICAgIH1cblxuICAgIHZhciB1cmw7XG4gICAgaWYgKHRoaXMuc291cmNlUm9vdCAhPSBudWxsXG4gICAgICAgICYmICh1cmwgPSB1dGlsLnVybFBhcnNlKHRoaXMuc291cmNlUm9vdCkpKSB7XG4gICAgICAvLyBYWFg6IGZpbGU6Ly8gVVJJcyBhbmQgYWJzb2x1dGUgcGF0aHMgbGVhZCB0byB1bmV4cGVjdGVkIGJlaGF2aW9yIGZvclxuICAgICAgLy8gbWFueSB1c2Vycy4gV2UgY2FuIGhlbHAgdGhlbSBvdXQgd2hlbiB0aGV5IGV4cGVjdCBmaWxlOi8vIFVSSXMgdG9cbiAgICAgIC8vIGJlaGF2ZSBsaWtlIGl0IHdvdWxkIGlmIHRoZXkgd2VyZSBydW5uaW5nIGEgbG9jYWwgSFRUUCBzZXJ2ZXIuIFNlZVxuICAgICAgLy8gaHR0cHM6Ly9idWd6aWxsYS5tb3ppbGxhLm9yZy9zaG93X2J1Zy5jZ2k/aWQ9ODg1NTk3LlxuICAgICAgdmFyIGZpbGVVcmlBYnNQYXRoID0gcmVsYXRpdmVTb3VyY2UucmVwbGFjZSgvXmZpbGU6XFwvXFwvLywgXCJcIik7XG4gICAgICBpZiAodXJsLnNjaGVtZSA9PSBcImZpbGVcIlxuICAgICAgICAgICYmIHRoaXMuX3NvdXJjZXMuaGFzKGZpbGVVcmlBYnNQYXRoKSkge1xuICAgICAgICByZXR1cm4gdGhpcy5zb3VyY2VzQ29udGVudFt0aGlzLl9zb3VyY2VzLmluZGV4T2YoZmlsZVVyaUFic1BhdGgpXVxuICAgICAgfVxuXG4gICAgICBpZiAoKCF1cmwucGF0aCB8fCB1cmwucGF0aCA9PSBcIi9cIilcbiAgICAgICAgICAmJiB0aGlzLl9zb3VyY2VzLmhhcyhcIi9cIiArIHJlbGF0aXZlU291cmNlKSkge1xuICAgICAgICByZXR1cm4gdGhpcy5zb3VyY2VzQ29udGVudFt0aGlzLl9zb3VyY2VzLmluZGV4T2YoXCIvXCIgKyByZWxhdGl2ZVNvdXJjZSldO1xuICAgICAgfVxuICAgIH1cblxuICAgIC8vIFRoaXMgZnVuY3Rpb24gaXMgdXNlZCByZWN1cnNpdmVseSBmcm9tXG4gICAgLy8gSW5kZXhlZFNvdXJjZU1hcENvbnN1bWVyLnByb3RvdHlwZS5zb3VyY2VDb250ZW50Rm9yLiBJbiB0aGF0IGNhc2UsIHdlXG4gICAgLy8gZG9uJ3Qgd2FudCB0byB0aHJvdyBpZiB3ZSBjYW4ndCBmaW5kIHRoZSBzb3VyY2UgLSB3ZSBqdXN0IHdhbnQgdG9cbiAgICAvLyByZXR1cm4gbnVsbCwgc28gd2UgcHJvdmlkZSBhIGZsYWcgdG8gZXhpdCBncmFjZWZ1bGx5LlxuICAgIGlmIChudWxsT25NaXNzaW5nKSB7XG4gICAgICByZXR1cm4gbnVsbDtcbiAgICB9XG4gICAgZWxzZSB7XG4gICAgICB0aHJvdyBuZXcgRXJyb3IoJ1wiJyArIHJlbGF0aXZlU291cmNlICsgJ1wiIGlzIG5vdCBpbiB0aGUgU291cmNlTWFwLicpO1xuICAgIH1cbiAgfTtcblxuLyoqXG4gKiBSZXR1cm5zIHRoZSBnZW5lcmF0ZWQgbGluZSBhbmQgY29sdW1uIGluZm9ybWF0aW9uIGZvciB0aGUgb3JpZ2luYWwgc291cmNlLFxuICogbGluZSwgYW5kIGNvbHVtbiBwb3NpdGlvbnMgcHJvdmlkZWQuIFRoZSBvbmx5IGFyZ3VtZW50IGlzIGFuIG9iamVjdCB3aXRoXG4gKiB0aGUgZm9sbG93aW5nIHByb3BlcnRpZXM6XG4gKlxuICogICAtIHNvdXJjZTogVGhlIGZpbGVuYW1lIG9mIHRoZSBvcmlnaW5hbCBzb3VyY2UuXG4gKiAgIC0gbGluZTogVGhlIGxpbmUgbnVtYmVyIGluIHRoZSBvcmlnaW5hbCBzb3VyY2UuICBUaGUgbGluZSBudW1iZXJcbiAqICAgICBpcyAxLWJhc2VkLlxuICogICAtIGNvbHVtbjogVGhlIGNvbHVtbiBudW1iZXIgaW4gdGhlIG9yaWdpbmFsIHNvdXJjZS4gIFRoZSBjb2x1bW5cbiAqICAgICBudW1iZXIgaXMgMC1iYXNlZC5cbiAqICAgLSBiaWFzOiBFaXRoZXIgJ1NvdXJjZU1hcENvbnN1bWVyLkdSRUFURVNUX0xPV0VSX0JPVU5EJyBvclxuICogICAgICdTb3VyY2VNYXBDb25zdW1lci5MRUFTVF9VUFBFUl9CT1VORCcuIFNwZWNpZmllcyB3aGV0aGVyIHRvIHJldHVybiB0aGVcbiAqICAgICBjbG9zZXN0IGVsZW1lbnQgdGhhdCBpcyBzbWFsbGVyIHRoYW4gb3IgZ3JlYXRlciB0aGFuIHRoZSBvbmUgd2UgYXJlXG4gKiAgICAgc2VhcmNoaW5nIGZvciwgcmVzcGVjdGl2ZWx5LCBpZiB0aGUgZXhhY3QgZWxlbWVudCBjYW5ub3QgYmUgZm91bmQuXG4gKiAgICAgRGVmYXVsdHMgdG8gJ1NvdXJjZU1hcENvbnN1bWVyLkdSRUFURVNUX0xPV0VSX0JPVU5EJy5cbiAqXG4gKiBhbmQgYW4gb2JqZWN0IGlzIHJldHVybmVkIHdpdGggdGhlIGZvbGxvd2luZyBwcm9wZXJ0aWVzOlxuICpcbiAqICAgLSBsaW5lOiBUaGUgbGluZSBudW1iZXIgaW4gdGhlIGdlbmVyYXRlZCBzb3VyY2UsIG9yIG51bGwuICBUaGVcbiAqICAgICBsaW5lIG51bWJlciBpcyAxLWJhc2VkLlxuICogICAtIGNvbHVtbjogVGhlIGNvbHVtbiBudW1iZXIgaW4gdGhlIGdlbmVyYXRlZCBzb3VyY2UsIG9yIG51bGwuXG4gKiAgICAgVGhlIGNvbHVtbiBudW1iZXIgaXMgMC1iYXNlZC5cbiAqL1xuQmFzaWNTb3VyY2VNYXBDb25zdW1lci5wcm90b3R5cGUuZ2VuZXJhdGVkUG9zaXRpb25Gb3IgPVxuICBmdW5jdGlvbiBTb3VyY2VNYXBDb25zdW1lcl9nZW5lcmF0ZWRQb3NpdGlvbkZvcihhQXJncykge1xuICAgIHZhciBzb3VyY2UgPSB1dGlsLmdldEFyZyhhQXJncywgJ3NvdXJjZScpO1xuICAgIHNvdXJjZSA9IHRoaXMuX2ZpbmRTb3VyY2VJbmRleChzb3VyY2UpO1xuICAgIGlmIChzb3VyY2UgPCAwKSB7XG4gICAgICByZXR1cm4ge1xuICAgICAgICBsaW5lOiBudWxsLFxuICAgICAgICBjb2x1bW46IG51bGwsXG4gICAgICAgIGxhc3RDb2x1bW46IG51bGxcbiAgICAgIH07XG4gICAgfVxuXG4gICAgdmFyIG5lZWRsZSA9IHtcbiAgICAgIHNvdXJjZTogc291cmNlLFxuICAgICAgb3JpZ2luYWxMaW5lOiB1dGlsLmdldEFyZyhhQXJncywgJ2xpbmUnKSxcbiAgICAgIG9yaWdpbmFsQ29sdW1uOiB1dGlsLmdldEFyZyhhQXJncywgJ2NvbHVtbicpXG4gICAgfTtcblxuICAgIHZhciBpbmRleCA9IHRoaXMuX2ZpbmRNYXBwaW5nKFxuICAgICAgbmVlZGxlLFxuICAgICAgdGhpcy5fb3JpZ2luYWxNYXBwaW5ncyxcbiAgICAgIFwib3JpZ2luYWxMaW5lXCIsXG4gICAgICBcIm9yaWdpbmFsQ29sdW1uXCIsXG4gICAgICB1dGlsLmNvbXBhcmVCeU9yaWdpbmFsUG9zaXRpb25zLFxuICAgICAgdXRpbC5nZXRBcmcoYUFyZ3MsICdiaWFzJywgU291cmNlTWFwQ29uc3VtZXIuR1JFQVRFU1RfTE9XRVJfQk9VTkQpXG4gICAgKTtcblxuICAgIGlmIChpbmRleCA+PSAwKSB7XG4gICAgICB2YXIgbWFwcGluZyA9IHRoaXMuX29yaWdpbmFsTWFwcGluZ3NbaW5kZXhdO1xuXG4gICAgICBpZiAobWFwcGluZy5zb3VyY2UgPT09IG5lZWRsZS5zb3VyY2UpIHtcbiAgICAgICAgcmV0dXJuIHtcbiAgICAgICAgICBsaW5lOiB1dGlsLmdldEFyZyhtYXBwaW5nLCAnZ2VuZXJhdGVkTGluZScsIG51bGwpLFxuICAgICAgICAgIGNvbHVtbjogdXRpbC5nZXRBcmcobWFwcGluZywgJ2dlbmVyYXRlZENvbHVtbicsIG51bGwpLFxuICAgICAgICAgIGxhc3RDb2x1bW46IHV0aWwuZ2V0QXJnKG1hcHBpbmcsICdsYXN0R2VuZXJhdGVkQ29sdW1uJywgbnVsbClcbiAgICAgICAgfTtcbiAgICAgIH1cbiAgICB9XG5cbiAgICByZXR1cm4ge1xuICAgICAgbGluZTogbnVsbCxcbiAgICAgIGNvbHVtbjogbnVsbCxcbiAgICAgIGxhc3RDb2x1bW46IG51bGxcbiAgICB9O1xuICB9O1xuXG5leHBvcnRzLkJhc2ljU291cmNlTWFwQ29uc3VtZXIgPSBCYXNpY1NvdXJjZU1hcENvbnN1bWVyO1xuXG4vKipcbiAqIEFuIEluZGV4ZWRTb3VyY2VNYXBDb25zdW1lciBpbnN0YW5jZSByZXByZXNlbnRzIGEgcGFyc2VkIHNvdXJjZSBtYXAgd2hpY2hcbiAqIHdlIGNhbiBxdWVyeSBmb3IgaW5mb3JtYXRpb24uIEl0IGRpZmZlcnMgZnJvbSBCYXNpY1NvdXJjZU1hcENvbnN1bWVyIGluXG4gKiB0aGF0IGl0IHRha2VzIFwiaW5kZXhlZFwiIHNvdXJjZSBtYXBzIChpLmUuIG9uZXMgd2l0aCBhIFwic2VjdGlvbnNcIiBmaWVsZCkgYXNcbiAqIGlucHV0LlxuICpcbiAqIFRoZSBmaXJzdCBwYXJhbWV0ZXIgaXMgYSByYXcgc291cmNlIG1hcCAoZWl0aGVyIGFzIGEgSlNPTiBzdHJpbmcsIG9yIGFscmVhZHlcbiAqIHBhcnNlZCB0byBhbiBvYmplY3QpLiBBY2NvcmRpbmcgdG8gdGhlIHNwZWMgZm9yIGluZGV4ZWQgc291cmNlIG1hcHMsIHRoZXlcbiAqIGhhdmUgdGhlIGZvbGxvd2luZyBhdHRyaWJ1dGVzOlxuICpcbiAqICAgLSB2ZXJzaW9uOiBXaGljaCB2ZXJzaW9uIG9mIHRoZSBzb3VyY2UgbWFwIHNwZWMgdGhpcyBtYXAgaXMgZm9sbG93aW5nLlxuICogICAtIGZpbGU6IE9wdGlvbmFsLiBUaGUgZ2VuZXJhdGVkIGZpbGUgdGhpcyBzb3VyY2UgbWFwIGlzIGFzc29jaWF0ZWQgd2l0aC5cbiAqICAgLSBzZWN0aW9uczogQSBsaXN0IG9mIHNlY3Rpb24gZGVmaW5pdGlvbnMuXG4gKlxuICogRWFjaCB2YWx1ZSB1bmRlciB0aGUgXCJzZWN0aW9uc1wiIGZpZWxkIGhhcyB0d28gZmllbGRzOlxuICogICAtIG9mZnNldDogVGhlIG9mZnNldCBpbnRvIHRoZSBvcmlnaW5hbCBzcGVjaWZpZWQgYXQgd2hpY2ggdGhpcyBzZWN0aW9uXG4gKiAgICAgICBiZWdpbnMgdG8gYXBwbHksIGRlZmluZWQgYXMgYW4gb2JqZWN0IHdpdGggYSBcImxpbmVcIiBhbmQgXCJjb2x1bW5cIlxuICogICAgICAgZmllbGQuXG4gKiAgIC0gbWFwOiBBIHNvdXJjZSBtYXAgZGVmaW5pdGlvbi4gVGhpcyBzb3VyY2UgbWFwIGNvdWxkIGFsc28gYmUgaW5kZXhlZCxcbiAqICAgICAgIGJ1dCBkb2Vzbid0IGhhdmUgdG8gYmUuXG4gKlxuICogSW5zdGVhZCBvZiB0aGUgXCJtYXBcIiBmaWVsZCwgaXQncyBhbHNvIHBvc3NpYmxlIHRvIGhhdmUgYSBcInVybFwiIGZpZWxkXG4gKiBzcGVjaWZ5aW5nIGEgVVJMIHRvIHJldHJpZXZlIGEgc291cmNlIG1hcCBmcm9tLCBidXQgdGhhdCdzIGN1cnJlbnRseVxuICogdW5zdXBwb3J0ZWQuXG4gKlxuICogSGVyZSdzIGFuIGV4YW1wbGUgc291cmNlIG1hcCwgdGFrZW4gZnJvbSB0aGUgc291cmNlIG1hcCBzcGVjWzBdLCBidXRcbiAqIG1vZGlmaWVkIHRvIG9taXQgYSBzZWN0aW9uIHdoaWNoIHVzZXMgdGhlIFwidXJsXCIgZmllbGQuXG4gKlxuICogIHtcbiAqICAgIHZlcnNpb24gOiAzLFxuICogICAgZmlsZTogXCJhcHAuanNcIixcbiAqICAgIHNlY3Rpb25zOiBbe1xuICogICAgICBvZmZzZXQ6IHtsaW5lOjEwMCwgY29sdW1uOjEwfSxcbiAqICAgICAgbWFwOiB7XG4gKiAgICAgICAgdmVyc2lvbiA6IDMsXG4gKiAgICAgICAgZmlsZTogXCJzZWN0aW9uLmpzXCIsXG4gKiAgICAgICAgc291cmNlczogW1wiZm9vLmpzXCIsIFwiYmFyLmpzXCJdLFxuICogICAgICAgIG5hbWVzOiBbXCJzcmNcIiwgXCJtYXBzXCIsIFwiYXJlXCIsIFwiZnVuXCJdLFxuICogICAgICAgIG1hcHBpbmdzOiBcIkFBQUEsRTs7QUJDREU7XCJcbiAqICAgICAgfVxuICogICAgfV0sXG4gKiAgfVxuICpcbiAqIFRoZSBzZWNvbmQgcGFyYW1ldGVyLCBpZiBnaXZlbiwgaXMgYSBzdHJpbmcgd2hvc2UgdmFsdWUgaXMgdGhlIFVSTFxuICogYXQgd2hpY2ggdGhlIHNvdXJjZSBtYXAgd2FzIGZvdW5kLiAgVGhpcyBVUkwgaXMgdXNlZCB0byBjb21wdXRlIHRoZVxuICogc291cmNlcyBhcnJheS5cbiAqXG4gKiBbMF06IGh0dHBzOi8vZG9jcy5nb29nbGUuY29tL2RvY3VtZW50L2QvMVUxUkdBZWhRd1J5cFVUb3ZGMUtSbHBpT0Z6ZTBiLV8yZ2M2ZkFIMEtZMGsvZWRpdCNoZWFkaW5nPWguNTM1ZXMzeGVwcmd0XG4gKi9cbmZ1bmN0aW9uIEluZGV4ZWRTb3VyY2VNYXBDb25zdW1lcihhU291cmNlTWFwLCBhU291cmNlTWFwVVJMKSB7XG4gIHZhciBzb3VyY2VNYXAgPSBhU291cmNlTWFwO1xuICBpZiAodHlwZW9mIGFTb3VyY2VNYXAgPT09ICdzdHJpbmcnKSB7XG4gICAgc291cmNlTWFwID0gdXRpbC5wYXJzZVNvdXJjZU1hcElucHV0KGFTb3VyY2VNYXApO1xuICB9XG5cbiAgdmFyIHZlcnNpb24gPSB1dGlsLmdldEFyZyhzb3VyY2VNYXAsICd2ZXJzaW9uJyk7XG4gIHZhciBzZWN0aW9ucyA9IHV0aWwuZ2V0QXJnKHNvdXJjZU1hcCwgJ3NlY3Rpb25zJyk7XG5cbiAgaWYgKHZlcnNpb24gIT0gdGhpcy5fdmVyc2lvbikge1xuICAgIHRocm93IG5ldyBFcnJvcignVW5zdXBwb3J0ZWQgdmVyc2lvbjogJyArIHZlcnNpb24pO1xuICB9XG5cbiAgdGhpcy5fc291cmNlcyA9IG5ldyBBcnJheVNldCgpO1xuICB0aGlzLl9uYW1lcyA9IG5ldyBBcnJheVNldCgpO1xuXG4gIHZhciBsYXN0T2Zmc2V0ID0ge1xuICAgIGxpbmU6IC0xLFxuICAgIGNvbHVtbjogMFxuICB9O1xuICB0aGlzLl9zZWN0aW9ucyA9IHNlY3Rpb25zLm1hcChmdW5jdGlvbiAocykge1xuICAgIGlmIChzLnVybCkge1xuICAgICAgLy8gVGhlIHVybCBmaWVsZCB3aWxsIHJlcXVpcmUgc3VwcG9ydCBmb3IgYXN5bmNocm9uaWNpdHkuXG4gICAgICAvLyBTZWUgaHR0cHM6Ly9naXRodWIuY29tL21vemlsbGEvc291cmNlLW1hcC9pc3N1ZXMvMTZcbiAgICAgIHRocm93IG5ldyBFcnJvcignU3VwcG9ydCBmb3IgdXJsIGZpZWxkIGluIHNlY3Rpb25zIG5vdCBpbXBsZW1lbnRlZC4nKTtcbiAgICB9XG4gICAgdmFyIG9mZnNldCA9IHV0aWwuZ2V0QXJnKHMsICdvZmZzZXQnKTtcbiAgICB2YXIgb2Zmc2V0TGluZSA9IHV0aWwuZ2V0QXJnKG9mZnNldCwgJ2xpbmUnKTtcbiAgICB2YXIgb2Zmc2V0Q29sdW1uID0gdXRpbC5nZXRBcmcob2Zmc2V0LCAnY29sdW1uJyk7XG5cbiAgICBpZiAob2Zmc2V0TGluZSA8IGxhc3RPZmZzZXQubGluZSB8fFxuICAgICAgICAob2Zmc2V0TGluZSA9PT0gbGFzdE9mZnNldC5saW5lICYmIG9mZnNldENvbHVtbiA8IGxhc3RPZmZzZXQuY29sdW1uKSkge1xuICAgICAgdGhyb3cgbmV3IEVycm9yKCdTZWN0aW9uIG9mZnNldHMgbXVzdCBiZSBvcmRlcmVkIGFuZCBub24tb3ZlcmxhcHBpbmcuJyk7XG4gICAgfVxuICAgIGxhc3RPZmZzZXQgPSBvZmZzZXQ7XG5cbiAgICByZXR1cm4ge1xuICAgICAgZ2VuZXJhdGVkT2Zmc2V0OiB7XG4gICAgICAgIC8vIFRoZSBvZmZzZXQgZmllbGRzIGFyZSAwLWJhc2VkLCBidXQgd2UgdXNlIDEtYmFzZWQgaW5kaWNlcyB3aGVuXG4gICAgICAgIC8vIGVuY29kaW5nL2RlY29kaW5nIGZyb20gVkxRLlxuICAgICAgICBnZW5lcmF0ZWRMaW5lOiBvZmZzZXRMaW5lICsgMSxcbiAgICAgICAgZ2VuZXJhdGVkQ29sdW1uOiBvZmZzZXRDb2x1bW4gKyAxXG4gICAgICB9LFxuICAgICAgY29uc3VtZXI6IG5ldyBTb3VyY2VNYXBDb25zdW1lcih1dGlsLmdldEFyZyhzLCAnbWFwJyksIGFTb3VyY2VNYXBVUkwpXG4gICAgfVxuICB9KTtcbn1cblxuSW5kZXhlZFNvdXJjZU1hcENvbnN1bWVyLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoU291cmNlTWFwQ29uc3VtZXIucHJvdG90eXBlKTtcbkluZGV4ZWRTb3VyY2VNYXBDb25zdW1lci5wcm90b3R5cGUuY29uc3RydWN0b3IgPSBTb3VyY2VNYXBDb25zdW1lcjtcblxuLyoqXG4gKiBUaGUgdmVyc2lvbiBvZiB0aGUgc291cmNlIG1hcHBpbmcgc3BlYyB0aGF0IHdlIGFyZSBjb25zdW1pbmcuXG4gKi9cbkluZGV4ZWRTb3VyY2VNYXBDb25zdW1lci5wcm90b3R5cGUuX3ZlcnNpb24gPSAzO1xuXG4vKipcbiAqIFRoZSBsaXN0IG9mIG9yaWdpbmFsIHNvdXJjZXMuXG4gKi9cbk9iamVjdC5kZWZpbmVQcm9wZXJ0eShJbmRleGVkU291cmNlTWFwQ29uc3VtZXIucHJvdG90eXBlLCAnc291cmNlcycsIHtcbiAgZ2V0OiBmdW5jdGlvbiAoKSB7XG4gICAgdmFyIHNvdXJjZXMgPSBbXTtcbiAgICBmb3IgKHZhciBpID0gMDsgaSA8IHRoaXMuX3NlY3Rpb25zLmxlbmd0aDsgaSsrKSB7XG4gICAgICBmb3IgKHZhciBqID0gMDsgaiA8IHRoaXMuX3NlY3Rpb25zW2ldLmNvbnN1bWVyLnNvdXJjZXMubGVuZ3RoOyBqKyspIHtcbiAgICAgICAgc291cmNlcy5wdXNoKHRoaXMuX3NlY3Rpb25zW2ldLmNvbnN1bWVyLnNvdXJjZXNbal0pO1xuICAgICAgfVxuICAgIH1cbiAgICByZXR1cm4gc291cmNlcztcbiAgfVxufSk7XG5cbi8qKlxuICogUmV0dXJucyB0aGUgb3JpZ2luYWwgc291cmNlLCBsaW5lLCBhbmQgY29sdW1uIGluZm9ybWF0aW9uIGZvciB0aGUgZ2VuZXJhdGVkXG4gKiBzb3VyY2UncyBsaW5lIGFuZCBjb2x1bW4gcG9zaXRpb25zIHByb3ZpZGVkLiBUaGUgb25seSBhcmd1bWVudCBpcyBhbiBvYmplY3RcbiAqIHdpdGggdGhlIGZvbGxvd2luZyBwcm9wZXJ0aWVzOlxuICpcbiAqICAgLSBsaW5lOiBUaGUgbGluZSBudW1iZXIgaW4gdGhlIGdlbmVyYXRlZCBzb3VyY2UuICBUaGUgbGluZSBudW1iZXJcbiAqICAgICBpcyAxLWJhc2VkLlxuICogICAtIGNvbHVtbjogVGhlIGNvbHVtbiBudW1iZXIgaW4gdGhlIGdlbmVyYXRlZCBzb3VyY2UuICBUaGUgY29sdW1uXG4gKiAgICAgbnVtYmVyIGlzIDAtYmFzZWQuXG4gKlxuICogYW5kIGFuIG9iamVjdCBpcyByZXR1cm5lZCB3aXRoIHRoZSBmb2xsb3dpbmcgcHJvcGVydGllczpcbiAqXG4gKiAgIC0gc291cmNlOiBUaGUgb3JpZ2luYWwgc291cmNlIGZpbGUsIG9yIG51bGwuXG4gKiAgIC0gbGluZTogVGhlIGxpbmUgbnVtYmVyIGluIHRoZSBvcmlnaW5hbCBzb3VyY2UsIG9yIG51bGwuICBUaGVcbiAqICAgICBsaW5lIG51bWJlciBpcyAxLWJhc2VkLlxuICogICAtIGNvbHVtbjogVGhlIGNvbHVtbiBudW1iZXIgaW4gdGhlIG9yaWdpbmFsIHNvdXJjZSwgb3IgbnVsbC4gIFRoZVxuICogICAgIGNvbHVtbiBudW1iZXIgaXMgMC1iYXNlZC5cbiAqICAgLSBuYW1lOiBUaGUgb3JpZ2luYWwgaWRlbnRpZmllciwgb3IgbnVsbC5cbiAqL1xuSW5kZXhlZFNvdXJjZU1hcENvbnN1bWVyLnByb3RvdHlwZS5vcmlnaW5hbFBvc2l0aW9uRm9yID1cbiAgZnVuY3Rpb24gSW5kZXhlZFNvdXJjZU1hcENvbnN1bWVyX29yaWdpbmFsUG9zaXRpb25Gb3IoYUFyZ3MpIHtcbiAgICB2YXIgbmVlZGxlID0ge1xuICAgICAgZ2VuZXJhdGVkTGluZTogdXRpbC5nZXRBcmcoYUFyZ3MsICdsaW5lJyksXG4gICAgICBnZW5lcmF0ZWRDb2x1bW46IHV0aWwuZ2V0QXJnKGFBcmdzLCAnY29sdW1uJylcbiAgICB9O1xuXG4gICAgLy8gRmluZCB0aGUgc2VjdGlvbiBjb250YWluaW5nIHRoZSBnZW5lcmF0ZWQgcG9zaXRpb24gd2UncmUgdHJ5aW5nIHRvIG1hcFxuICAgIC8vIHRvIGFuIG9yaWdpbmFsIHBvc2l0aW9uLlxuICAgIHZhciBzZWN0aW9uSW5kZXggPSBiaW5hcnlTZWFyY2guc2VhcmNoKG5lZWRsZSwgdGhpcy5fc2VjdGlvbnMsXG4gICAgICBmdW5jdGlvbihuZWVkbGUsIHNlY3Rpb24pIHtcbiAgICAgICAgdmFyIGNtcCA9IG5lZWRsZS5nZW5lcmF0ZWRMaW5lIC0gc2VjdGlvbi5nZW5lcmF0ZWRPZmZzZXQuZ2VuZXJhdGVkTGluZTtcbiAgICAgICAgaWYgKGNtcCkge1xuICAgICAgICAgIHJldHVybiBjbXA7XG4gICAgICAgIH1cblxuICAgICAgICByZXR1cm4gKG5lZWRsZS5nZW5lcmF0ZWRDb2x1bW4gLVxuICAgICAgICAgICAgICAgIHNlY3Rpb24uZ2VuZXJhdGVkT2Zmc2V0LmdlbmVyYXRlZENvbHVtbik7XG4gICAgICB9KTtcbiAgICB2YXIgc2VjdGlvbiA9IHRoaXMuX3NlY3Rpb25zW3NlY3Rpb25JbmRleF07XG5cbiAgICBpZiAoIXNlY3Rpb24pIHtcbiAgICAgIHJldHVybiB7XG4gICAgICAgIHNvdXJjZTogbnVsbCxcbiAgICAgICAgbGluZTogbnVsbCxcbiAgICAgICAgY29sdW1uOiBudWxsLFxuICAgICAgICBuYW1lOiBudWxsXG4gICAgICB9O1xuICAgIH1cblxuICAgIHJldHVybiBzZWN0aW9uLmNvbnN1bWVyLm9yaWdpbmFsUG9zaXRpb25Gb3Ioe1xuICAgICAgbGluZTogbmVlZGxlLmdlbmVyYXRlZExpbmUgLVxuICAgICAgICAoc2VjdGlvbi5nZW5lcmF0ZWRPZmZzZXQuZ2VuZXJhdGVkTGluZSAtIDEpLFxuICAgICAgY29sdW1uOiBuZWVkbGUuZ2VuZXJhdGVkQ29sdW1uIC1cbiAgICAgICAgKHNlY3Rpb24uZ2VuZXJhdGVkT2Zmc2V0LmdlbmVyYXRlZExpbmUgPT09IG5lZWRsZS5nZW5lcmF0ZWRMaW5lXG4gICAgICAgICA/IHNlY3Rpb24uZ2VuZXJhdGVkT2Zmc2V0LmdlbmVyYXRlZENvbHVtbiAtIDFcbiAgICAgICAgIDogMCksXG4gICAgICBiaWFzOiBhQXJncy5iaWFzXG4gICAgfSk7XG4gIH07XG5cbi8qKlxuICogUmV0dXJuIHRydWUgaWYgd2UgaGF2ZSB0aGUgc291cmNlIGNvbnRlbnQgZm9yIGV2ZXJ5IHNvdXJjZSBpbiB0aGUgc291cmNlXG4gKiBtYXAsIGZhbHNlIG90aGVyd2lzZS5cbiAqL1xuSW5kZXhlZFNvdXJjZU1hcENvbnN1bWVyLnByb3RvdHlwZS5oYXNDb250ZW50c09mQWxsU291cmNlcyA9XG4gIGZ1bmN0aW9uIEluZGV4ZWRTb3VyY2VNYXBDb25zdW1lcl9oYXNDb250ZW50c09mQWxsU291cmNlcygpIHtcbiAgICByZXR1cm4gdGhpcy5fc2VjdGlvbnMuZXZlcnkoZnVuY3Rpb24gKHMpIHtcbiAgICAgIHJldHVybiBzLmNvbnN1bWVyLmhhc0NvbnRlbnRzT2ZBbGxTb3VyY2VzKCk7XG4gICAgfSk7XG4gIH07XG5cbi8qKlxuICogUmV0dXJucyB0aGUgb3JpZ2luYWwgc291cmNlIGNvbnRlbnQuIFRoZSBvbmx5IGFyZ3VtZW50IGlzIHRoZSB1cmwgb2YgdGhlXG4gKiBvcmlnaW5hbCBzb3VyY2UgZmlsZS4gUmV0dXJucyBudWxsIGlmIG5vIG9yaWdpbmFsIHNvdXJjZSBjb250ZW50IGlzXG4gKiBhdmFpbGFibGUuXG4gKi9cbkluZGV4ZWRTb3VyY2VNYXBDb25zdW1lci5wcm90b3R5cGUuc291cmNlQ29udGVudEZvciA9XG4gIGZ1bmN0aW9uIEluZGV4ZWRTb3VyY2VNYXBDb25zdW1lcl9zb3VyY2VDb250ZW50Rm9yKGFTb3VyY2UsIG51bGxPbk1pc3NpbmcpIHtcbiAgICBmb3IgKHZhciBpID0gMDsgaSA8IHRoaXMuX3NlY3Rpb25zLmxlbmd0aDsgaSsrKSB7XG4gICAgICB2YXIgc2VjdGlvbiA9IHRoaXMuX3NlY3Rpb25zW2ldO1xuXG4gICAgICB2YXIgY29udGVudCA9IHNlY3Rpb24uY29uc3VtZXIuc291cmNlQ29udGVudEZvcihhU291cmNlLCB0cnVlKTtcbiAgICAgIGlmIChjb250ZW50IHx8IGNvbnRlbnQgPT09ICcnKSB7XG4gICAgICAgIHJldHVybiBjb250ZW50O1xuICAgICAgfVxuICAgIH1cbiAgICBpZiAobnVsbE9uTWlzc2luZykge1xuICAgICAgcmV0dXJuIG51bGw7XG4gICAgfVxuICAgIGVsc2Uge1xuICAgICAgdGhyb3cgbmV3IEVycm9yKCdcIicgKyBhU291cmNlICsgJ1wiIGlzIG5vdCBpbiB0aGUgU291cmNlTWFwLicpO1xuICAgIH1cbiAgfTtcblxuLyoqXG4gKiBSZXR1cm5zIHRoZSBnZW5lcmF0ZWQgbGluZSBhbmQgY29sdW1uIGluZm9ybWF0aW9uIGZvciB0aGUgb3JpZ2luYWwgc291cmNlLFxuICogbGluZSwgYW5kIGNvbHVtbiBwb3NpdGlvbnMgcHJvdmlkZWQuIFRoZSBvbmx5IGFyZ3VtZW50IGlzIGFuIG9iamVjdCB3aXRoXG4gKiB0aGUgZm9sbG93aW5nIHByb3BlcnRpZXM6XG4gKlxuICogICAtIHNvdXJjZTogVGhlIGZpbGVuYW1lIG9mIHRoZSBvcmlnaW5hbCBzb3VyY2UuXG4gKiAgIC0gbGluZTogVGhlIGxpbmUgbnVtYmVyIGluIHRoZSBvcmlnaW5hbCBzb3VyY2UuICBUaGUgbGluZSBudW1iZXJcbiAqICAgICBpcyAxLWJhc2VkLlxuICogICAtIGNvbHVtbjogVGhlIGNvbHVtbiBudW1iZXIgaW4gdGhlIG9yaWdpbmFsIHNvdXJjZS4gIFRoZSBjb2x1bW5cbiAqICAgICBudW1iZXIgaXMgMC1iYXNlZC5cbiAqXG4gKiBhbmQgYW4gb2JqZWN0IGlzIHJldHVybmVkIHdpdGggdGhlIGZvbGxvd2luZyBwcm9wZXJ0aWVzOlxuICpcbiAqICAgLSBsaW5lOiBUaGUgbGluZSBudW1iZXIgaW4gdGhlIGdlbmVyYXRlZCBzb3VyY2UsIG9yIG51bGwuICBUaGVcbiAqICAgICBsaW5lIG51bWJlciBpcyAxLWJhc2VkLiBcbiAqICAgLSBjb2x1bW46IFRoZSBjb2x1bW4gbnVtYmVyIGluIHRoZSBnZW5lcmF0ZWQgc291cmNlLCBvciBudWxsLlxuICogICAgIFRoZSBjb2x1bW4gbnVtYmVyIGlzIDAtYmFzZWQuXG4gKi9cbkluZGV4ZWRTb3VyY2VNYXBDb25zdW1lci5wcm90b3R5cGUuZ2VuZXJhdGVkUG9zaXRpb25Gb3IgPVxuICBmdW5jdGlvbiBJbmRleGVkU291cmNlTWFwQ29uc3VtZXJfZ2VuZXJhdGVkUG9zaXRpb25Gb3IoYUFyZ3MpIHtcbiAgICBmb3IgKHZhciBpID0gMDsgaSA8IHRoaXMuX3NlY3Rpb25zLmxlbmd0aDsgaSsrKSB7XG4gICAgICB2YXIgc2VjdGlvbiA9IHRoaXMuX3NlY3Rpb25zW2ldO1xuXG4gICAgICAvLyBPbmx5IGNvbnNpZGVyIHRoaXMgc2VjdGlvbiBpZiB0aGUgcmVxdWVzdGVkIHNvdXJjZSBpcyBpbiB0aGUgbGlzdCBvZlxuICAgICAgLy8gc291cmNlcyBvZiB0aGUgY29uc3VtZXIuXG4gICAgICBpZiAoc2VjdGlvbi5jb25zdW1lci5fZmluZFNvdXJjZUluZGV4KHV0aWwuZ2V0QXJnKGFBcmdzLCAnc291cmNlJykpID09PSAtMSkge1xuICAgICAgICBjb250aW51ZTtcbiAgICAgIH1cbiAgICAgIHZhciBnZW5lcmF0ZWRQb3NpdGlvbiA9IHNlY3Rpb24uY29uc3VtZXIuZ2VuZXJhdGVkUG9zaXRpb25Gb3IoYUFyZ3MpO1xuICAgICAgaWYgKGdlbmVyYXRlZFBvc2l0aW9uKSB7XG4gICAgICAgIHZhciByZXQgPSB7XG4gICAgICAgICAgbGluZTogZ2VuZXJhdGVkUG9zaXRpb24ubGluZSArXG4gICAgICAgICAgICAoc2VjdGlvbi5nZW5lcmF0ZWRPZmZzZXQuZ2VuZXJhdGVkTGluZSAtIDEpLFxuICAgICAgICAgIGNvbHVtbjogZ2VuZXJhdGVkUG9zaXRpb24uY29sdW1uICtcbiAgICAgICAgICAgIChzZWN0aW9uLmdlbmVyYXRlZE9mZnNldC5nZW5lcmF0ZWRMaW5lID09PSBnZW5lcmF0ZWRQb3NpdGlvbi5saW5lXG4gICAgICAgICAgICAgPyBzZWN0aW9uLmdlbmVyYXRlZE9mZnNldC5nZW5lcmF0ZWRDb2x1bW4gLSAxXG4gICAgICAgICAgICAgOiAwKVxuICAgICAgICB9O1xuICAgICAgICByZXR1cm4gcmV0O1xuICAgICAgfVxuICAgIH1cblxuICAgIHJldHVybiB7XG4gICAgICBsaW5lOiBudWxsLFxuICAgICAgY29sdW1uOiBudWxsXG4gICAgfTtcbiAgfTtcblxuLyoqXG4gKiBQYXJzZSB0aGUgbWFwcGluZ3MgaW4gYSBzdHJpbmcgaW4gdG8gYSBkYXRhIHN0cnVjdHVyZSB3aGljaCB3ZSBjYW4gZWFzaWx5XG4gKiBxdWVyeSAodGhlIG9yZGVyZWQgYXJyYXlzIGluIHRoZSBgdGhpcy5fX2dlbmVyYXRlZE1hcHBpbmdzYCBhbmRcbiAqIGB0aGlzLl9fb3JpZ2luYWxNYXBwaW5nc2AgcHJvcGVydGllcykuXG4gKi9cbkluZGV4ZWRTb3VyY2VNYXBDb25zdW1lci5wcm90b3R5cGUuX3BhcnNlTWFwcGluZ3MgPVxuICBmdW5jdGlvbiBJbmRleGVkU291cmNlTWFwQ29uc3VtZXJfcGFyc2VNYXBwaW5ncyhhU3RyLCBhU291cmNlUm9vdCkge1xuICAgIHRoaXMuX19nZW5lcmF0ZWRNYXBwaW5ncyA9IFtdO1xuICAgIHRoaXMuX19vcmlnaW5hbE1hcHBpbmdzID0gW107XG4gICAgZm9yICh2YXIgaSA9IDA7IGkgPCB0aGlzLl9zZWN0aW9ucy5sZW5ndGg7IGkrKykge1xuICAgICAgdmFyIHNlY3Rpb24gPSB0aGlzLl9zZWN0aW9uc1tpXTtcbiAgICAgIHZhciBzZWN0aW9uTWFwcGluZ3MgPSBzZWN0aW9uLmNvbnN1bWVyLl9nZW5lcmF0ZWRNYXBwaW5ncztcbiAgICAgIGZvciAodmFyIGogPSAwOyBqIDwgc2VjdGlvbk1hcHBpbmdzLmxlbmd0aDsgaisrKSB7XG4gICAgICAgIHZhciBtYXBwaW5nID0gc2VjdGlvbk1hcHBpbmdzW2pdO1xuXG4gICAgICAgIHZhciBzb3VyY2UgPSBzZWN0aW9uLmNvbnN1bWVyLl9zb3VyY2VzLmF0KG1hcHBpbmcuc291cmNlKTtcbiAgICAgICAgaWYoc291cmNlICE9PSBudWxsKSB7XG4gICAgICAgICAgc291cmNlID0gdXRpbC5jb21wdXRlU291cmNlVVJMKHNlY3Rpb24uY29uc3VtZXIuc291cmNlUm9vdCwgc291cmNlLCB0aGlzLl9zb3VyY2VNYXBVUkwpO1xuICAgICAgICB9XG4gICAgICAgIHRoaXMuX3NvdXJjZXMuYWRkKHNvdXJjZSk7XG4gICAgICAgIHNvdXJjZSA9IHRoaXMuX3NvdXJjZXMuaW5kZXhPZihzb3VyY2UpO1xuXG4gICAgICAgIHZhciBuYW1lID0gbnVsbDtcbiAgICAgICAgaWYgKG1hcHBpbmcubmFtZSkge1xuICAgICAgICAgIG5hbWUgPSBzZWN0aW9uLmNvbnN1bWVyLl9uYW1lcy5hdChtYXBwaW5nLm5hbWUpO1xuICAgICAgICAgIHRoaXMuX25hbWVzLmFkZChuYW1lKTtcbiAgICAgICAgICBuYW1lID0gdGhpcy5fbmFtZXMuaW5kZXhPZihuYW1lKTtcbiAgICAgICAgfVxuXG4gICAgICAgIC8vIFRoZSBtYXBwaW5ncyBjb21pbmcgZnJvbSB0aGUgY29uc3VtZXIgZm9yIHRoZSBzZWN0aW9uIGhhdmVcbiAgICAgICAgLy8gZ2VuZXJhdGVkIHBvc2l0aW9ucyByZWxhdGl2ZSB0byB0aGUgc3RhcnQgb2YgdGhlIHNlY3Rpb24sIHNvIHdlXG4gICAgICAgIC8vIG5lZWQgdG8gb2Zmc2V0IHRoZW0gdG8gYmUgcmVsYXRpdmUgdG8gdGhlIHN0YXJ0IG9mIHRoZSBjb25jYXRlbmF0ZWRcbiAgICAgICAgLy8gZ2VuZXJhdGVkIGZpbGUuXG4gICAgICAgIHZhciBhZGp1c3RlZE1hcHBpbmcgPSB7XG4gICAgICAgICAgc291cmNlOiBzb3VyY2UsXG4gICAgICAgICAgZ2VuZXJhdGVkTGluZTogbWFwcGluZy5nZW5lcmF0ZWRMaW5lICtcbiAgICAgICAgICAgIChzZWN0aW9uLmdlbmVyYXRlZE9mZnNldC5nZW5lcmF0ZWRMaW5lIC0gMSksXG4gICAgICAgICAgZ2VuZXJhdGVkQ29sdW1uOiBtYXBwaW5nLmdlbmVyYXRlZENvbHVtbiArXG4gICAgICAgICAgICAoc2VjdGlvbi5nZW5lcmF0ZWRPZmZzZXQuZ2VuZXJhdGVkTGluZSA9PT0gbWFwcGluZy5nZW5lcmF0ZWRMaW5lXG4gICAgICAgICAgICA/IHNlY3Rpb24uZ2VuZXJhdGVkT2Zmc2V0LmdlbmVyYXRlZENvbHVtbiAtIDFcbiAgICAgICAgICAgIDogMCksXG4gICAgICAgICAgb3JpZ2luYWxMaW5lOiBtYXBwaW5nLm9yaWdpbmFsTGluZSxcbiAgICAgICAgICBvcmlnaW5hbENvbHVtbjogbWFwcGluZy5vcmlnaW5hbENvbHVtbixcbiAgICAgICAgICBuYW1lOiBuYW1lXG4gICAgICAgIH07XG5cbiAgICAgICAgdGhpcy5fX2dlbmVyYXRlZE1hcHBpbmdzLnB1c2goYWRqdXN0ZWRNYXBwaW5nKTtcbiAgICAgICAgaWYgKHR5cGVvZiBhZGp1c3RlZE1hcHBpbmcub3JpZ2luYWxMaW5lID09PSAnbnVtYmVyJykge1xuICAgICAgICAgIHRoaXMuX19vcmlnaW5hbE1hcHBpbmdzLnB1c2goYWRqdXN0ZWRNYXBwaW5nKTtcbiAgICAgICAgfVxuICAgICAgfVxuICAgIH1cblxuICAgIHF1aWNrU29ydCh0aGlzLl9fZ2VuZXJhdGVkTWFwcGluZ3MsIHV0aWwuY29tcGFyZUJ5R2VuZXJhdGVkUG9zaXRpb25zRGVmbGF0ZWQpO1xuICAgIHF1aWNrU29ydCh0aGlzLl9fb3JpZ2luYWxNYXBwaW5ncywgdXRpbC5jb21wYXJlQnlPcmlnaW5hbFBvc2l0aW9ucyk7XG4gIH07XG5cbmV4cG9ydHMuSW5kZXhlZFNvdXJjZU1hcENvbnN1bWVyID0gSW5kZXhlZFNvdXJjZU1hcENvbnN1bWVyO1xuIiwgIi8qIC0qLSBNb2RlOiBqczsganMtaW5kZW50LWxldmVsOiAyOyAtKi0gKi9cbi8qXG4gKiBDb3B5cmlnaHQgMjAxMSBNb3ppbGxhIEZvdW5kYXRpb24gYW5kIGNvbnRyaWJ1dG9yc1xuICogTGljZW5zZWQgdW5kZXIgdGhlIE5ldyBCU0QgbGljZW5zZS4gU2VlIExJQ0VOU0Ugb3I6XG4gKiBodHRwOi8vb3BlbnNvdXJjZS5vcmcvbGljZW5zZXMvQlNELTMtQ2xhdXNlXG4gKi9cblxudmFyIFNvdXJjZU1hcEdlbmVyYXRvciA9IHJlcXVpcmUoJy4vc291cmNlLW1hcC1nZW5lcmF0b3InKS5Tb3VyY2VNYXBHZW5lcmF0b3I7XG52YXIgdXRpbCA9IHJlcXVpcmUoJy4vdXRpbCcpO1xuXG4vLyBNYXRjaGVzIGEgV2luZG93cy1zdHlsZSBgXFxyXFxuYCBuZXdsaW5lIG9yIGEgYFxcbmAgbmV3bGluZSB1c2VkIGJ5IGFsbCBvdGhlclxuLy8gb3BlcmF0aW5nIHN5c3RlbXMgdGhlc2UgZGF5cyAoY2FwdHVyaW5nIHRoZSByZXN1bHQpLlxudmFyIFJFR0VYX05FV0xJTkUgPSAvKFxccj9cXG4pLztcblxuLy8gTmV3bGluZSBjaGFyYWN0ZXIgY29kZSBmb3IgY2hhckNvZGVBdCgpIGNvbXBhcmlzb25zXG52YXIgTkVXTElORV9DT0RFID0gMTA7XG5cbi8vIFByaXZhdGUgc3ltYm9sIGZvciBpZGVudGlmeWluZyBgU291cmNlTm9kZWBzIHdoZW4gbXVsdGlwbGUgdmVyc2lvbnMgb2Zcbi8vIHRoZSBzb3VyY2UtbWFwIGxpYnJhcnkgYXJlIGxvYWRlZC4gVGhpcyBNVVNUIE5PVCBDSEFOR0UgYWNyb3NzXG4vLyB2ZXJzaW9ucyFcbnZhciBpc1NvdXJjZU5vZGUgPSBcIiQkJGlzU291cmNlTm9kZSQkJFwiO1xuXG4vKipcbiAqIFNvdXJjZU5vZGVzIHByb3ZpZGUgYSB3YXkgdG8gYWJzdHJhY3Qgb3ZlciBpbnRlcnBvbGF0aW5nL2NvbmNhdGVuYXRpbmdcbiAqIHNuaXBwZXRzIG9mIGdlbmVyYXRlZCBKYXZhU2NyaXB0IHNvdXJjZSBjb2RlIHdoaWxlIG1haW50YWluaW5nIHRoZSBsaW5lIGFuZFxuICogY29sdW1uIGluZm9ybWF0aW9uIGFzc29jaWF0ZWQgd2l0aCB0aGUgb3JpZ2luYWwgc291cmNlIGNvZGUuXG4gKlxuICogQHBhcmFtIGFMaW5lIFRoZSBvcmlnaW5hbCBsaW5lIG51bWJlci5cbiAqIEBwYXJhbSBhQ29sdW1uIFRoZSBvcmlnaW5hbCBjb2x1bW4gbnVtYmVyLlxuICogQHBhcmFtIGFTb3VyY2UgVGhlIG9yaWdpbmFsIHNvdXJjZSdzIGZpbGVuYW1lLlxuICogQHBhcmFtIGFDaHVua3MgT3B0aW9uYWwuIEFuIGFycmF5IG9mIHN0cmluZ3Mgd2hpY2ggYXJlIHNuaXBwZXRzIG9mXG4gKiAgICAgICAgZ2VuZXJhdGVkIEpTLCBvciBvdGhlciBTb3VyY2VOb2Rlcy5cbiAqIEBwYXJhbSBhTmFtZSBUaGUgb3JpZ2luYWwgaWRlbnRpZmllci5cbiAqL1xuZnVuY3Rpb24gU291cmNlTm9kZShhTGluZSwgYUNvbHVtbiwgYVNvdXJjZSwgYUNodW5rcywgYU5hbWUpIHtcbiAgdGhpcy5jaGlsZHJlbiA9IFtdO1xuICB0aGlzLnNvdXJjZUNvbnRlbnRzID0ge307XG4gIHRoaXMubGluZSA9IGFMaW5lID09IG51bGwgPyBudWxsIDogYUxpbmU7XG4gIHRoaXMuY29sdW1uID0gYUNvbHVtbiA9PSBudWxsID8gbnVsbCA6IGFDb2x1bW47XG4gIHRoaXMuc291cmNlID0gYVNvdXJjZSA9PSBudWxsID8gbnVsbCA6IGFTb3VyY2U7XG4gIHRoaXMubmFtZSA9IGFOYW1lID09IG51bGwgPyBudWxsIDogYU5hbWU7XG4gIHRoaXNbaXNTb3VyY2VOb2RlXSA9IHRydWU7XG4gIGlmIChhQ2h1bmtzICE9IG51bGwpIHRoaXMuYWRkKGFDaHVua3MpO1xufVxuXG4vKipcbiAqIENyZWF0ZXMgYSBTb3VyY2VOb2RlIGZyb20gZ2VuZXJhdGVkIGNvZGUgYW5kIGEgU291cmNlTWFwQ29uc3VtZXIuXG4gKlxuICogQHBhcmFtIGFHZW5lcmF0ZWRDb2RlIFRoZSBnZW5lcmF0ZWQgY29kZVxuICogQHBhcmFtIGFTb3VyY2VNYXBDb25zdW1lciBUaGUgU291cmNlTWFwIGZvciB0aGUgZ2VuZXJhdGVkIGNvZGVcbiAqIEBwYXJhbSBhUmVsYXRpdmVQYXRoIE9wdGlvbmFsLiBUaGUgcGF0aCB0aGF0IHJlbGF0aXZlIHNvdXJjZXMgaW4gdGhlXG4gKiAgICAgICAgU291cmNlTWFwQ29uc3VtZXIgc2hvdWxkIGJlIHJlbGF0aXZlIHRvLlxuICovXG5Tb3VyY2VOb2RlLmZyb21TdHJpbmdXaXRoU291cmNlTWFwID1cbiAgZnVuY3Rpb24gU291cmNlTm9kZV9mcm9tU3RyaW5nV2l0aFNvdXJjZU1hcChhR2VuZXJhdGVkQ29kZSwgYVNvdXJjZU1hcENvbnN1bWVyLCBhUmVsYXRpdmVQYXRoKSB7XG4gICAgLy8gVGhlIFNvdXJjZU5vZGUgd2Ugd2FudCB0byBmaWxsIHdpdGggdGhlIGdlbmVyYXRlZCBjb2RlXG4gICAgLy8gYW5kIHRoZSBTb3VyY2VNYXBcbiAgICB2YXIgbm9kZSA9IG5ldyBTb3VyY2VOb2RlKCk7XG5cbiAgICAvLyBBbGwgZXZlbiBpbmRpY2VzIG9mIHRoaXMgYXJyYXkgYXJlIG9uZSBsaW5lIG9mIHRoZSBnZW5lcmF0ZWQgY29kZSxcbiAgICAvLyB3aGlsZSBhbGwgb2RkIGluZGljZXMgYXJlIHRoZSBuZXdsaW5lcyBiZXR3ZWVuIHR3byBhZGphY2VudCBsaW5lc1xuICAgIC8vIChzaW5jZSBgUkVHRVhfTkVXTElORWAgY2FwdHVyZXMgaXRzIG1hdGNoKS5cbiAgICAvLyBQcm9jZXNzZWQgZnJhZ21lbnRzIGFyZSBhY2Nlc3NlZCBieSBjYWxsaW5nIGBzaGlmdE5leHRMaW5lYC5cbiAgICB2YXIgcmVtYWluaW5nTGluZXMgPSBhR2VuZXJhdGVkQ29kZS5zcGxpdChSRUdFWF9ORVdMSU5FKTtcbiAgICB2YXIgcmVtYWluaW5nTGluZXNJbmRleCA9IDA7XG4gICAgdmFyIHNoaWZ0TmV4dExpbmUgPSBmdW5jdGlvbigpIHtcbiAgICAgIHZhciBsaW5lQ29udGVudHMgPSBnZXROZXh0TGluZSgpO1xuICAgICAgLy8gVGhlIGxhc3QgbGluZSBvZiBhIGZpbGUgbWlnaHQgbm90IGhhdmUgYSBuZXdsaW5lLlxuICAgICAgdmFyIG5ld0xpbmUgPSBnZXROZXh0TGluZSgpIHx8IFwiXCI7XG4gICAgICByZXR1cm4gbGluZUNvbnRlbnRzICsgbmV3TGluZTtcblxuICAgICAgZnVuY3Rpb24gZ2V0TmV4dExpbmUoKSB7XG4gICAgICAgIHJldHVybiByZW1haW5pbmdMaW5lc0luZGV4IDwgcmVtYWluaW5nTGluZXMubGVuZ3RoID9cbiAgICAgICAgICAgIHJlbWFpbmluZ0xpbmVzW3JlbWFpbmluZ0xpbmVzSW5kZXgrK10gOiB1bmRlZmluZWQ7XG4gICAgICB9XG4gICAgfTtcblxuICAgIC8vIFdlIG5lZWQgdG8gcmVtZW1iZXIgdGhlIHBvc2l0aW9uIG9mIFwicmVtYWluaW5nTGluZXNcIlxuICAgIHZhciBsYXN0R2VuZXJhdGVkTGluZSA9IDEsIGxhc3RHZW5lcmF0ZWRDb2x1bW4gPSAwO1xuXG4gICAgLy8gVGhlIGdlbmVyYXRlIFNvdXJjZU5vZGVzIHdlIG5lZWQgYSBjb2RlIHJhbmdlLlxuICAgIC8vIFRvIGV4dHJhY3QgaXQgY3VycmVudCBhbmQgbGFzdCBtYXBwaW5nIGlzIHVzZWQuXG4gICAgLy8gSGVyZSB3ZSBzdG9yZSB0aGUgbGFzdCBtYXBwaW5nLlxuICAgIHZhciBsYXN0TWFwcGluZyA9IG51bGw7XG5cbiAgICBhU291cmNlTWFwQ29uc3VtZXIuZWFjaE1hcHBpbmcoZnVuY3Rpb24gKG1hcHBpbmcpIHtcbiAgICAgIGlmIChsYXN0TWFwcGluZyAhPT0gbnVsbCkge1xuICAgICAgICAvLyBXZSBhZGQgdGhlIGNvZGUgZnJvbSBcImxhc3RNYXBwaW5nXCIgdG8gXCJtYXBwaW5nXCI6XG4gICAgICAgIC8vIEZpcnN0IGNoZWNrIGlmIHRoZXJlIGlzIGEgbmV3IGxpbmUgaW4gYmV0d2Vlbi5cbiAgICAgICAgaWYgKGxhc3RHZW5lcmF0ZWRMaW5lIDwgbWFwcGluZy5nZW5lcmF0ZWRMaW5lKSB7XG4gICAgICAgICAgLy8gQXNzb2NpYXRlIGZpcnN0IGxpbmUgd2l0aCBcImxhc3RNYXBwaW5nXCJcbiAgICAgICAgICBhZGRNYXBwaW5nV2l0aENvZGUobGFzdE1hcHBpbmcsIHNoaWZ0TmV4dExpbmUoKSk7XG4gICAgICAgICAgbGFzdEdlbmVyYXRlZExpbmUrKztcbiAgICAgICAgICBsYXN0R2VuZXJhdGVkQ29sdW1uID0gMDtcbiAgICAgICAgICAvLyBUaGUgcmVtYWluaW5nIGNvZGUgaXMgYWRkZWQgd2l0aG91dCBtYXBwaW5nXG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgLy8gVGhlcmUgaXMgbm8gbmV3IGxpbmUgaW4gYmV0d2Vlbi5cbiAgICAgICAgICAvLyBBc3NvY2lhdGUgdGhlIGNvZGUgYmV0d2VlbiBcImxhc3RHZW5lcmF0ZWRDb2x1bW5cIiBhbmRcbiAgICAgICAgICAvLyBcIm1hcHBpbmcuZ2VuZXJhdGVkQ29sdW1uXCIgd2l0aCBcImxhc3RNYXBwaW5nXCJcbiAgICAgICAgICB2YXIgbmV4dExpbmUgPSByZW1haW5pbmdMaW5lc1tyZW1haW5pbmdMaW5lc0luZGV4XSB8fCAnJztcbiAgICAgICAgICB2YXIgY29kZSA9IG5leHRMaW5lLnN1YnN0cigwLCBtYXBwaW5nLmdlbmVyYXRlZENvbHVtbiAtXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbGFzdEdlbmVyYXRlZENvbHVtbik7XG4gICAgICAgICAgcmVtYWluaW5nTGluZXNbcmVtYWluaW5nTGluZXNJbmRleF0gPSBuZXh0TGluZS5zdWJzdHIobWFwcGluZy5nZW5lcmF0ZWRDb2x1bW4gLVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGxhc3RHZW5lcmF0ZWRDb2x1bW4pO1xuICAgICAgICAgIGxhc3RHZW5lcmF0ZWRDb2x1bW4gPSBtYXBwaW5nLmdlbmVyYXRlZENvbHVtbjtcbiAgICAgICAgICBhZGRNYXBwaW5nV2l0aENvZGUobGFzdE1hcHBpbmcsIGNvZGUpO1xuICAgICAgICAgIC8vIE5vIG1vcmUgcmVtYWluaW5nIGNvZGUsIGNvbnRpbnVlXG4gICAgICAgICAgbGFzdE1hcHBpbmcgPSBtYXBwaW5nO1xuICAgICAgICAgIHJldHVybjtcbiAgICAgICAgfVxuICAgICAgfVxuICAgICAgLy8gV2UgYWRkIHRoZSBnZW5lcmF0ZWQgY29kZSB1bnRpbCB0aGUgZmlyc3QgbWFwcGluZ1xuICAgICAgLy8gdG8gdGhlIFNvdXJjZU5vZGUgd2l0aG91dCBhbnkgbWFwcGluZy5cbiAgICAgIC8vIEVhY2ggbGluZSBpcyBhZGRlZCBhcyBzZXBhcmF0ZSBzdHJpbmcuXG4gICAgICB3aGlsZSAobGFzdEdlbmVyYXRlZExpbmUgPCBtYXBwaW5nLmdlbmVyYXRlZExpbmUpIHtcbiAgICAgICAgbm9kZS5hZGQoc2hpZnROZXh0TGluZSgpKTtcbiAgICAgICAgbGFzdEdlbmVyYXRlZExpbmUrKztcbiAgICAgIH1cbiAgICAgIGlmIChsYXN0R2VuZXJhdGVkQ29sdW1uIDwgbWFwcGluZy5nZW5lcmF0ZWRDb2x1bW4pIHtcbiAgICAgICAgdmFyIG5leHRMaW5lID0gcmVtYWluaW5nTGluZXNbcmVtYWluaW5nTGluZXNJbmRleF0gfHwgJyc7XG4gICAgICAgIG5vZGUuYWRkKG5leHRMaW5lLnN1YnN0cigwLCBtYXBwaW5nLmdlbmVyYXRlZENvbHVtbikpO1xuICAgICAgICByZW1haW5pbmdMaW5lc1tyZW1haW5pbmdMaW5lc0luZGV4XSA9IG5leHRMaW5lLnN1YnN0cihtYXBwaW5nLmdlbmVyYXRlZENvbHVtbik7XG4gICAgICAgIGxhc3RHZW5lcmF0ZWRDb2x1bW4gPSBtYXBwaW5nLmdlbmVyYXRlZENvbHVtbjtcbiAgICAgIH1cbiAgICAgIGxhc3RNYXBwaW5nID0gbWFwcGluZztcbiAgICB9LCB0aGlzKTtcbiAgICAvLyBXZSBoYXZlIHByb2Nlc3NlZCBhbGwgbWFwcGluZ3MuXG4gICAgaWYgKHJlbWFpbmluZ0xpbmVzSW5kZXggPCByZW1haW5pbmdMaW5lcy5sZW5ndGgpIHtcbiAgICAgIGlmIChsYXN0TWFwcGluZykge1xuICAgICAgICAvLyBBc3NvY2lhdGUgdGhlIHJlbWFpbmluZyBjb2RlIGluIHRoZSBjdXJyZW50IGxpbmUgd2l0aCBcImxhc3RNYXBwaW5nXCJcbiAgICAgICAgYWRkTWFwcGluZ1dpdGhDb2RlKGxhc3RNYXBwaW5nLCBzaGlmdE5leHRMaW5lKCkpO1xuICAgICAgfVxuICAgICAgLy8gYW5kIGFkZCB0aGUgcmVtYWluaW5nIGxpbmVzIHdpdGhvdXQgYW55IG1hcHBpbmdcbiAgICAgIG5vZGUuYWRkKHJlbWFpbmluZ0xpbmVzLnNwbGljZShyZW1haW5pbmdMaW5lc0luZGV4KS5qb2luKFwiXCIpKTtcbiAgICB9XG5cbiAgICAvLyBDb3B5IHNvdXJjZXNDb250ZW50IGludG8gU291cmNlTm9kZVxuICAgIGFTb3VyY2VNYXBDb25zdW1lci5zb3VyY2VzLmZvckVhY2goZnVuY3Rpb24gKHNvdXJjZUZpbGUpIHtcbiAgICAgIHZhciBjb250ZW50ID0gYVNvdXJjZU1hcENvbnN1bWVyLnNvdXJjZUNvbnRlbnRGb3Ioc291cmNlRmlsZSk7XG4gICAgICBpZiAoY29udGVudCAhPSBudWxsKSB7XG4gICAgICAgIGlmIChhUmVsYXRpdmVQYXRoICE9IG51bGwpIHtcbiAgICAgICAgICBzb3VyY2VGaWxlID0gdXRpbC5qb2luKGFSZWxhdGl2ZVBhdGgsIHNvdXJjZUZpbGUpO1xuICAgICAgICB9XG4gICAgICAgIG5vZGUuc2V0U291cmNlQ29udGVudChzb3VyY2VGaWxlLCBjb250ZW50KTtcbiAgICAgIH1cbiAgICB9KTtcblxuICAgIHJldHVybiBub2RlO1xuXG4gICAgZnVuY3Rpb24gYWRkTWFwcGluZ1dpdGhDb2RlKG1hcHBpbmcsIGNvZGUpIHtcbiAgICAgIGlmIChtYXBwaW5nID09PSBudWxsIHx8IG1hcHBpbmcuc291cmNlID09PSB1bmRlZmluZWQpIHtcbiAgICAgICAgbm9kZS5hZGQoY29kZSk7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICB2YXIgc291cmNlID0gYVJlbGF0aXZlUGF0aFxuICAgICAgICAgID8gdXRpbC5qb2luKGFSZWxhdGl2ZVBhdGgsIG1hcHBpbmcuc291cmNlKVxuICAgICAgICAgIDogbWFwcGluZy5zb3VyY2U7XG4gICAgICAgIG5vZGUuYWRkKG5ldyBTb3VyY2VOb2RlKG1hcHBpbmcub3JpZ2luYWxMaW5lLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBtYXBwaW5nLm9yaWdpbmFsQ29sdW1uLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBzb3VyY2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvZGUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1hcHBpbmcubmFtZSkpO1xuICAgICAgfVxuICAgIH1cbiAgfTtcblxuLyoqXG4gKiBBZGQgYSBjaHVuayBvZiBnZW5lcmF0ZWQgSlMgdG8gdGhpcyBzb3VyY2Ugbm9kZS5cbiAqXG4gKiBAcGFyYW0gYUNodW5rIEEgc3RyaW5nIHNuaXBwZXQgb2YgZ2VuZXJhdGVkIEpTIGNvZGUsIGFub3RoZXIgaW5zdGFuY2Ugb2ZcbiAqICAgICAgICBTb3VyY2VOb2RlLCBvciBhbiBhcnJheSB3aGVyZSBlYWNoIG1lbWJlciBpcyBvbmUgb2YgdGhvc2UgdGhpbmdzLlxuICovXG5Tb3VyY2VOb2RlLnByb3RvdHlwZS5hZGQgPSBmdW5jdGlvbiBTb3VyY2VOb2RlX2FkZChhQ2h1bmspIHtcbiAgaWYgKEFycmF5LmlzQXJyYXkoYUNodW5rKSkge1xuICAgIGFDaHVuay5mb3JFYWNoKGZ1bmN0aW9uIChjaHVuaykge1xuICAgICAgdGhpcy5hZGQoY2h1bmspO1xuICAgIH0sIHRoaXMpO1xuICB9XG4gIGVsc2UgaWYgKGFDaHVua1tpc1NvdXJjZU5vZGVdIHx8IHR5cGVvZiBhQ2h1bmsgPT09IFwic3RyaW5nXCIpIHtcbiAgICBpZiAoYUNodW5rKSB7XG4gICAgICB0aGlzLmNoaWxkcmVuLnB1c2goYUNodW5rKTtcbiAgICB9XG4gIH1cbiAgZWxzZSB7XG4gICAgdGhyb3cgbmV3IFR5cGVFcnJvcihcbiAgICAgIFwiRXhwZWN0ZWQgYSBTb3VyY2VOb2RlLCBzdHJpbmcsIG9yIGFuIGFycmF5IG9mIFNvdXJjZU5vZGVzIGFuZCBzdHJpbmdzLiBHb3QgXCIgKyBhQ2h1bmtcbiAgICApO1xuICB9XG4gIHJldHVybiB0aGlzO1xufTtcblxuLyoqXG4gKiBBZGQgYSBjaHVuayBvZiBnZW5lcmF0ZWQgSlMgdG8gdGhlIGJlZ2lubmluZyBvZiB0aGlzIHNvdXJjZSBub2RlLlxuICpcbiAqIEBwYXJhbSBhQ2h1bmsgQSBzdHJpbmcgc25pcHBldCBvZiBnZW5lcmF0ZWQgSlMgY29kZSwgYW5vdGhlciBpbnN0YW5jZSBvZlxuICogICAgICAgIFNvdXJjZU5vZGUsIG9yIGFuIGFycmF5IHdoZXJlIGVhY2ggbWVtYmVyIGlzIG9uZSBvZiB0aG9zZSB0aGluZ3MuXG4gKi9cblNvdXJjZU5vZGUucHJvdG90eXBlLnByZXBlbmQgPSBmdW5jdGlvbiBTb3VyY2VOb2RlX3ByZXBlbmQoYUNodW5rKSB7XG4gIGlmIChBcnJheS5pc0FycmF5KGFDaHVuaykpIHtcbiAgICBmb3IgKHZhciBpID0gYUNodW5rLmxlbmd0aC0xOyBpID49IDA7IGktLSkge1xuICAgICAgdGhpcy5wcmVwZW5kKGFDaHVua1tpXSk7XG4gICAgfVxuICB9XG4gIGVsc2UgaWYgKGFDaHVua1tpc1NvdXJjZU5vZGVdIHx8IHR5cGVvZiBhQ2h1bmsgPT09IFwic3RyaW5nXCIpIHtcbiAgICB0aGlzLmNoaWxkcmVuLnVuc2hpZnQoYUNodW5rKTtcbiAgfVxuICBlbHNlIHtcbiAgICB0aHJvdyBuZXcgVHlwZUVycm9yKFxuICAgICAgXCJFeHBlY3RlZCBhIFNvdXJjZU5vZGUsIHN0cmluZywgb3IgYW4gYXJyYXkgb2YgU291cmNlTm9kZXMgYW5kIHN0cmluZ3MuIEdvdCBcIiArIGFDaHVua1xuICAgICk7XG4gIH1cbiAgcmV0dXJuIHRoaXM7XG59O1xuXG4vKipcbiAqIFdhbGsgb3ZlciB0aGUgdHJlZSBvZiBKUyBzbmlwcGV0cyBpbiB0aGlzIG5vZGUgYW5kIGl0cyBjaGlsZHJlbi4gVGhlXG4gKiB3YWxraW5nIGZ1bmN0aW9uIGlzIGNhbGxlZCBvbmNlIGZvciBlYWNoIHNuaXBwZXQgb2YgSlMgYW5kIGlzIHBhc3NlZCB0aGF0XG4gKiBzbmlwcGV0IGFuZCB0aGUgaXRzIG9yaWdpbmFsIGFzc29jaWF0ZWQgc291cmNlJ3MgbGluZS9jb2x1bW4gbG9jYXRpb24uXG4gKlxuICogQHBhcmFtIGFGbiBUaGUgdHJhdmVyc2FsIGZ1bmN0aW9uLlxuICovXG5Tb3VyY2VOb2RlLnByb3RvdHlwZS53YWxrID0gZnVuY3Rpb24gU291cmNlTm9kZV93YWxrKGFGbikge1xuICB2YXIgY2h1bms7XG4gIGZvciAodmFyIGkgPSAwLCBsZW4gPSB0aGlzLmNoaWxkcmVuLmxlbmd0aDsgaSA8IGxlbjsgaSsrKSB7XG4gICAgY2h1bmsgPSB0aGlzLmNoaWxkcmVuW2ldO1xuICAgIGlmIChjaHVua1tpc1NvdXJjZU5vZGVdKSB7XG4gICAgICBjaHVuay53YWxrKGFGbik7XG4gICAgfVxuICAgIGVsc2Uge1xuICAgICAgaWYgKGNodW5rICE9PSAnJykge1xuICAgICAgICBhRm4oY2h1bmssIHsgc291cmNlOiB0aGlzLnNvdXJjZSxcbiAgICAgICAgICAgICAgICAgICAgIGxpbmU6IHRoaXMubGluZSxcbiAgICAgICAgICAgICAgICAgICAgIGNvbHVtbjogdGhpcy5jb2x1bW4sXG4gICAgICAgICAgICAgICAgICAgICBuYW1lOiB0aGlzLm5hbWUgfSk7XG4gICAgICB9XG4gICAgfVxuICB9XG59O1xuXG4vKipcbiAqIExpa2UgYFN0cmluZy5wcm90b3R5cGUuam9pbmAgZXhjZXB0IGZvciBTb3VyY2VOb2Rlcy4gSW5zZXJ0cyBgYVN0cmAgYmV0d2VlblxuICogZWFjaCBvZiBgdGhpcy5jaGlsZHJlbmAuXG4gKlxuICogQHBhcmFtIGFTZXAgVGhlIHNlcGFyYXRvci5cbiAqL1xuU291cmNlTm9kZS5wcm90b3R5cGUuam9pbiA9IGZ1bmN0aW9uIFNvdXJjZU5vZGVfam9pbihhU2VwKSB7XG4gIHZhciBuZXdDaGlsZHJlbjtcbiAgdmFyIGk7XG4gIHZhciBsZW4gPSB0aGlzLmNoaWxkcmVuLmxlbmd0aDtcbiAgaWYgKGxlbiA+IDApIHtcbiAgICBuZXdDaGlsZHJlbiA9IFtdO1xuICAgIGZvciAoaSA9IDA7IGkgPCBsZW4tMTsgaSsrKSB7XG4gICAgICBuZXdDaGlsZHJlbi5wdXNoKHRoaXMuY2hpbGRyZW5baV0pO1xuICAgICAgbmV3Q2hpbGRyZW4ucHVzaChhU2VwKTtcbiAgICB9XG4gICAgbmV3Q2hpbGRyZW4ucHVzaCh0aGlzLmNoaWxkcmVuW2ldKTtcbiAgICB0aGlzLmNoaWxkcmVuID0gbmV3Q2hpbGRyZW47XG4gIH1cbiAgcmV0dXJuIHRoaXM7XG59O1xuXG4vKipcbiAqIENhbGwgU3RyaW5nLnByb3RvdHlwZS5yZXBsYWNlIG9uIHRoZSB2ZXJ5IHJpZ2h0LW1vc3Qgc291cmNlIHNuaXBwZXQuIFVzZWZ1bFxuICogZm9yIHRyaW1taW5nIHdoaXRlc3BhY2UgZnJvbSB0aGUgZW5kIG9mIGEgc291cmNlIG5vZGUsIGV0Yy5cbiAqXG4gKiBAcGFyYW0gYVBhdHRlcm4gVGhlIHBhdHRlcm4gdG8gcmVwbGFjZS5cbiAqIEBwYXJhbSBhUmVwbGFjZW1lbnQgVGhlIHRoaW5nIHRvIHJlcGxhY2UgdGhlIHBhdHRlcm4gd2l0aC5cbiAqL1xuU291cmNlTm9kZS5wcm90b3R5cGUucmVwbGFjZVJpZ2h0ID0gZnVuY3Rpb24gU291cmNlTm9kZV9yZXBsYWNlUmlnaHQoYVBhdHRlcm4sIGFSZXBsYWNlbWVudCkge1xuICB2YXIgbGFzdENoaWxkID0gdGhpcy5jaGlsZHJlblt0aGlzLmNoaWxkcmVuLmxlbmd0aCAtIDFdO1xuICBpZiAobGFzdENoaWxkW2lzU291cmNlTm9kZV0pIHtcbiAgICBsYXN0Q2hpbGQucmVwbGFjZVJpZ2h0KGFQYXR0ZXJuLCBhUmVwbGFjZW1lbnQpO1xuICB9XG4gIGVsc2UgaWYgKHR5cGVvZiBsYXN0Q2hpbGQgPT09ICdzdHJpbmcnKSB7XG4gICAgdGhpcy5jaGlsZHJlblt0aGlzLmNoaWxkcmVuLmxlbmd0aCAtIDFdID0gbGFzdENoaWxkLnJlcGxhY2UoYVBhdHRlcm4sIGFSZXBsYWNlbWVudCk7XG4gIH1cbiAgZWxzZSB7XG4gICAgdGhpcy5jaGlsZHJlbi5wdXNoKCcnLnJlcGxhY2UoYVBhdHRlcm4sIGFSZXBsYWNlbWVudCkpO1xuICB9XG4gIHJldHVybiB0aGlzO1xufTtcblxuLyoqXG4gKiBTZXQgdGhlIHNvdXJjZSBjb250ZW50IGZvciBhIHNvdXJjZSBmaWxlLiBUaGlzIHdpbGwgYmUgYWRkZWQgdG8gdGhlIFNvdXJjZU1hcEdlbmVyYXRvclxuICogaW4gdGhlIHNvdXJjZXNDb250ZW50IGZpZWxkLlxuICpcbiAqIEBwYXJhbSBhU291cmNlRmlsZSBUaGUgZmlsZW5hbWUgb2YgdGhlIHNvdXJjZSBmaWxlXG4gKiBAcGFyYW0gYVNvdXJjZUNvbnRlbnQgVGhlIGNvbnRlbnQgb2YgdGhlIHNvdXJjZSBmaWxlXG4gKi9cblNvdXJjZU5vZGUucHJvdG90eXBlLnNldFNvdXJjZUNvbnRlbnQgPVxuICBmdW5jdGlvbiBTb3VyY2VOb2RlX3NldFNvdXJjZUNvbnRlbnQoYVNvdXJjZUZpbGUsIGFTb3VyY2VDb250ZW50KSB7XG4gICAgdGhpcy5zb3VyY2VDb250ZW50c1t1dGlsLnRvU2V0U3RyaW5nKGFTb3VyY2VGaWxlKV0gPSBhU291cmNlQ29udGVudDtcbiAgfTtcblxuLyoqXG4gKiBXYWxrIG92ZXIgdGhlIHRyZWUgb2YgU291cmNlTm9kZXMuIFRoZSB3YWxraW5nIGZ1bmN0aW9uIGlzIGNhbGxlZCBmb3IgZWFjaFxuICogc291cmNlIGZpbGUgY29udGVudCBhbmQgaXMgcGFzc2VkIHRoZSBmaWxlbmFtZSBhbmQgc291cmNlIGNvbnRlbnQuXG4gKlxuICogQHBhcmFtIGFGbiBUaGUgdHJhdmVyc2FsIGZ1bmN0aW9uLlxuICovXG5Tb3VyY2VOb2RlLnByb3RvdHlwZS53YWxrU291cmNlQ29udGVudHMgPVxuICBmdW5jdGlvbiBTb3VyY2VOb2RlX3dhbGtTb3VyY2VDb250ZW50cyhhRm4pIHtcbiAgICBmb3IgKHZhciBpID0gMCwgbGVuID0gdGhpcy5jaGlsZHJlbi5sZW5ndGg7IGkgPCBsZW47IGkrKykge1xuICAgICAgaWYgKHRoaXMuY2hpbGRyZW5baV1baXNTb3VyY2VOb2RlXSkge1xuICAgICAgICB0aGlzLmNoaWxkcmVuW2ldLndhbGtTb3VyY2VDb250ZW50cyhhRm4pO1xuICAgICAgfVxuICAgIH1cblxuICAgIHZhciBzb3VyY2VzID0gT2JqZWN0LmtleXModGhpcy5zb3VyY2VDb250ZW50cyk7XG4gICAgZm9yICh2YXIgaSA9IDAsIGxlbiA9IHNvdXJjZXMubGVuZ3RoOyBpIDwgbGVuOyBpKyspIHtcbiAgICAgIGFGbih1dGlsLmZyb21TZXRTdHJpbmcoc291cmNlc1tpXSksIHRoaXMuc291cmNlQ29udGVudHNbc291cmNlc1tpXV0pO1xuICAgIH1cbiAgfTtcblxuLyoqXG4gKiBSZXR1cm4gdGhlIHN0cmluZyByZXByZXNlbnRhdGlvbiBvZiB0aGlzIHNvdXJjZSBub2RlLiBXYWxrcyBvdmVyIHRoZSB0cmVlXG4gKiBhbmQgY29uY2F0ZW5hdGVzIGFsbCB0aGUgdmFyaW91cyBzbmlwcGV0cyB0b2dldGhlciB0byBvbmUgc3RyaW5nLlxuICovXG5Tb3VyY2VOb2RlLnByb3RvdHlwZS50b1N0cmluZyA9IGZ1bmN0aW9uIFNvdXJjZU5vZGVfdG9TdHJpbmcoKSB7XG4gIHZhciBzdHIgPSBcIlwiO1xuICB0aGlzLndhbGsoZnVuY3Rpb24gKGNodW5rKSB7XG4gICAgc3RyICs9IGNodW5rO1xuICB9KTtcbiAgcmV0dXJuIHN0cjtcbn07XG5cbi8qKlxuICogUmV0dXJucyB0aGUgc3RyaW5nIHJlcHJlc2VudGF0aW9uIG9mIHRoaXMgc291cmNlIG5vZGUgYWxvbmcgd2l0aCBhIHNvdXJjZVxuICogbWFwLlxuICovXG5Tb3VyY2VOb2RlLnByb3RvdHlwZS50b1N0cmluZ1dpdGhTb3VyY2VNYXAgPSBmdW5jdGlvbiBTb3VyY2VOb2RlX3RvU3RyaW5nV2l0aFNvdXJjZU1hcChhQXJncykge1xuICB2YXIgZ2VuZXJhdGVkID0ge1xuICAgIGNvZGU6IFwiXCIsXG4gICAgbGluZTogMSxcbiAgICBjb2x1bW46IDBcbiAgfTtcbiAgdmFyIG1hcCA9IG5ldyBTb3VyY2VNYXBHZW5lcmF0b3IoYUFyZ3MpO1xuICB2YXIgc291cmNlTWFwcGluZ0FjdGl2ZSA9IGZhbHNlO1xuICB2YXIgbGFzdE9yaWdpbmFsU291cmNlID0gbnVsbDtcbiAgdmFyIGxhc3RPcmlnaW5hbExpbmUgPSBudWxsO1xuICB2YXIgbGFzdE9yaWdpbmFsQ29sdW1uID0gbnVsbDtcbiAgdmFyIGxhc3RPcmlnaW5hbE5hbWUgPSBudWxsO1xuICB0aGlzLndhbGsoZnVuY3Rpb24gKGNodW5rLCBvcmlnaW5hbCkge1xuICAgIGdlbmVyYXRlZC5jb2RlICs9IGNodW5rO1xuICAgIGlmIChvcmlnaW5hbC5zb3VyY2UgIT09IG51bGxcbiAgICAgICAgJiYgb3JpZ2luYWwubGluZSAhPT0gbnVsbFxuICAgICAgICAmJiBvcmlnaW5hbC5jb2x1bW4gIT09IG51bGwpIHtcbiAgICAgIGlmKGxhc3RPcmlnaW5hbFNvdXJjZSAhPT0gb3JpZ2luYWwuc291cmNlXG4gICAgICAgICB8fCBsYXN0T3JpZ2luYWxMaW5lICE9PSBvcmlnaW5hbC5saW5lXG4gICAgICAgICB8fCBsYXN0T3JpZ2luYWxDb2x1bW4gIT09IG9yaWdpbmFsLmNvbHVtblxuICAgICAgICAgfHwgbGFzdE9yaWdpbmFsTmFtZSAhPT0gb3JpZ2luYWwubmFtZSkge1xuICAgICAgICBtYXAuYWRkTWFwcGluZyh7XG4gICAgICAgICAgc291cmNlOiBvcmlnaW5hbC5zb3VyY2UsXG4gICAgICAgICAgb3JpZ2luYWw6IHtcbiAgICAgICAgICAgIGxpbmU6IG9yaWdpbmFsLmxpbmUsXG4gICAgICAgICAgICBjb2x1bW46IG9yaWdpbmFsLmNvbHVtblxuICAgICAgICAgIH0sXG4gICAgICAgICAgZ2VuZXJhdGVkOiB7XG4gICAgICAgICAgICBsaW5lOiBnZW5lcmF0ZWQubGluZSxcbiAgICAgICAgICAgIGNvbHVtbjogZ2VuZXJhdGVkLmNvbHVtblxuICAgICAgICAgIH0sXG4gICAgICAgICAgbmFtZTogb3JpZ2luYWwubmFtZVxuICAgICAgICB9KTtcbiAgICAgIH1cbiAgICAgIGxhc3RPcmlnaW5hbFNvdXJjZSA9IG9yaWdpbmFsLnNvdXJjZTtcbiAgICAgIGxhc3RPcmlnaW5hbExpbmUgPSBvcmlnaW5hbC5saW5lO1xuICAgICAgbGFzdE9yaWdpbmFsQ29sdW1uID0gb3JpZ2luYWwuY29sdW1uO1xuICAgICAgbGFzdE9yaWdpbmFsTmFtZSA9IG9yaWdpbmFsLm5hbWU7XG4gICAgICBzb3VyY2VNYXBwaW5nQWN0aXZlID0gdHJ1ZTtcbiAgICB9IGVsc2UgaWYgKHNvdXJjZU1hcHBpbmdBY3RpdmUpIHtcbiAgICAgIG1hcC5hZGRNYXBwaW5nKHtcbiAgICAgICAgZ2VuZXJhdGVkOiB7XG4gICAgICAgICAgbGluZTogZ2VuZXJhdGVkLmxpbmUsXG4gICAgICAgICAgY29sdW1uOiBnZW5lcmF0ZWQuY29sdW1uXG4gICAgICAgIH1cbiAgICAgIH0pO1xuICAgICAgbGFzdE9yaWdpbmFsU291cmNlID0gbnVsbDtcbiAgICAgIHNvdXJjZU1hcHBpbmdBY3RpdmUgPSBmYWxzZTtcbiAgICB9XG4gICAgZm9yICh2YXIgaWR4ID0gMCwgbGVuZ3RoID0gY2h1bmsubGVuZ3RoOyBpZHggPCBsZW5ndGg7IGlkeCsrKSB7XG4gICAgICBpZiAoY2h1bmsuY2hhckNvZGVBdChpZHgpID09PSBORVdMSU5FX0NPREUpIHtcbiAgICAgICAgZ2VuZXJhdGVkLmxpbmUrKztcbiAgICAgICAgZ2VuZXJhdGVkLmNvbHVtbiA9IDA7XG4gICAgICAgIC8vIE1hcHBpbmdzIGVuZCBhdCBlb2xcbiAgICAgICAgaWYgKGlkeCArIDEgPT09IGxlbmd0aCkge1xuICAgICAgICAgIGxhc3RPcmlnaW5hbFNvdXJjZSA9IG51bGw7XG4gICAgICAgICAgc291cmNlTWFwcGluZ0FjdGl2ZSA9IGZhbHNlO1xuICAgICAgICB9IGVsc2UgaWYgKHNvdXJjZU1hcHBpbmdBY3RpdmUpIHtcbiAgICAgICAgICBtYXAuYWRkTWFwcGluZyh7XG4gICAgICAgICAgICBzb3VyY2U6IG9yaWdpbmFsLnNvdXJjZSxcbiAgICAgICAgICAgIG9yaWdpbmFsOiB7XG4gICAgICAgICAgICAgIGxpbmU6IG9yaWdpbmFsLmxpbmUsXG4gICAgICAgICAgICAgIGNvbHVtbjogb3JpZ2luYWwuY29sdW1uXG4gICAgICAgICAgICB9LFxuICAgICAgICAgICAgZ2VuZXJhdGVkOiB7XG4gICAgICAgICAgICAgIGxpbmU6IGdlbmVyYXRlZC5saW5lLFxuICAgICAgICAgICAgICBjb2x1bW46IGdlbmVyYXRlZC5jb2x1bW5cbiAgICAgICAgICAgIH0sXG4gICAgICAgICAgICBuYW1lOiBvcmlnaW5hbC5uYW1lXG4gICAgICAgICAgfSk7XG4gICAgICAgIH1cbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIGdlbmVyYXRlZC5jb2x1bW4rKztcbiAgICAgIH1cbiAgICB9XG4gIH0pO1xuICB0aGlzLndhbGtTb3VyY2VDb250ZW50cyhmdW5jdGlvbiAoc291cmNlRmlsZSwgc291cmNlQ29udGVudCkge1xuICAgIG1hcC5zZXRTb3VyY2VDb250ZW50KHNvdXJjZUZpbGUsIHNvdXJjZUNvbnRlbnQpO1xuICB9KTtcblxuICByZXR1cm4geyBjb2RlOiBnZW5lcmF0ZWQuY29kZSwgbWFwOiBtYXAgfTtcbn07XG5cbmV4cG9ydHMuU291cmNlTm9kZSA9IFNvdXJjZU5vZGU7XG4iLCAiLypcbiAqIENvcHlyaWdodCAyMDA5LTIwMTEgTW96aWxsYSBGb3VuZGF0aW9uIGFuZCBjb250cmlidXRvcnNcbiAqIExpY2Vuc2VkIHVuZGVyIHRoZSBOZXcgQlNEIGxpY2Vuc2UuIFNlZSBMSUNFTlNFLnR4dCBvcjpcbiAqIGh0dHA6Ly9vcGVuc291cmNlLm9yZy9saWNlbnNlcy9CU0QtMy1DbGF1c2VcbiAqL1xuZXhwb3J0cy5Tb3VyY2VNYXBHZW5lcmF0b3IgPSByZXF1aXJlKCcuL2xpYi9zb3VyY2UtbWFwLWdlbmVyYXRvcicpLlNvdXJjZU1hcEdlbmVyYXRvcjtcbmV4cG9ydHMuU291cmNlTWFwQ29uc3VtZXIgPSByZXF1aXJlKCcuL2xpYi9zb3VyY2UtbWFwLWNvbnN1bWVyJykuU291cmNlTWFwQ29uc3VtZXI7XG5leHBvcnRzLlNvdXJjZU5vZGUgPSByZXF1aXJlKCcuL2xpYi9zb3VyY2Utbm9kZScpLlNvdXJjZU5vZGU7XG4iLCAiLy8gRW5oYW5jZWQgSmF2YVNjcmlwdCBFcnJvciBIYW5kbGVyIHdpdGggUGVyc2lzdGVudCBTdGF0dXMgQmFyXG4vLyBQcm92aWRlcyB1c2VyLWZyaWVuZGx5IGVycm9yIG1vbml0b3Jpbmcgd2l0aCBwZXJtYW5lbnQgdmlzaWJpbGl0eVxuXG5pbXBvcnQgeyBTb3VyY2VNYXBDb25zdW1lciB9IGZyb20gJ3NvdXJjZS1tYXAtanMnXG5cbi8vIEVycm9yIHR5cGUgZGVmaW5pdGlvbnNcbnR5cGUgRXJyb3JUeXBlID0gJ2phdmFzY3JpcHQnIHwgJ2ludGVyYWN0aW9uJyB8ICdwcm9taXNlJyB8ICdodHRwJyB8ICdhY3Rpb25jYWJsZScgfCAnbWFudWFsJyB8ICdzdGltdWx1cycgfCAnYXN5bmNqb2InO1xuXG4vLyBCYXNlIGVycm9yIGluZm8gaW50ZXJmYWNlXG5pbnRlcmZhY2UgQmFzZUVycm9ySW5mbyB7XG4gIG1lc3NhZ2U6IHN0cmluZztcbiAgdHlwZTogRXJyb3JUeXBlO1xuICB0aW1lc3RhbXA6IHN0cmluZztcbiAgZmlsZW5hbWU/OiBzdHJpbmc7XG4gIGxpbmVubz86IG51bWJlcjtcbiAgY29sbm8/OiBudW1iZXI7XG4gIGVycm9yPzogRXJyb3I7XG59XG5cbi8vIEphdmFTY3JpcHQvSW50ZXJhY3Rpb24gZXJyb3IgaW5mb1xuaW50ZXJmYWNlIEphdmFTY3JpcHRFcnJvckluZm8gZXh0ZW5kcyBCYXNlRXJyb3JJbmZvIHtcbiAgdHlwZTogJ2phdmFzY3JpcHQnIHwgJ2ludGVyYWN0aW9uJztcbiAgZmlsZW5hbWU/OiBzdHJpbmc7XG4gIGxpbmVubz86IG51bWJlcjtcbiAgY29sbm8/OiBudW1iZXI7XG4gIGVycm9yPzogRXJyb3I7XG59XG5cbi8vIFByb21pc2UgZXJyb3IgaW5mb1xuaW50ZXJmYWNlIFByb21pc2VFcnJvckluZm8gZXh0ZW5kcyBCYXNlRXJyb3JJbmZvIHtcbiAgdHlwZTogJ3Byb21pc2UnO1xuICBlcnJvcj86IGFueTtcbn1cblxuLy8gSFRUUCBlcnJvciBpbmZvXG5pbnRlcmZhY2UgSHR0cEVycm9ySW5mbyBleHRlbmRzIEJhc2VFcnJvckluZm8ge1xuICB0eXBlOiAnaHR0cCc7XG4gIHVybD86IHN0cmluZztcbiAgbWV0aG9kPzogc3RyaW5nO1xuICBzdGF0dXM/OiBudW1iZXI7XG4gIGpzb25FcnJvcj86IGFueTtcbn1cblxuLy8gQWN0aW9uQ2FibGUgZXJyb3IgaW5mb1xuaW50ZXJmYWNlIEFjdGlvbkNhYmxlRXJyb3JJbmZvIGV4dGVuZHMgQmFzZUVycm9ySW5mbyB7XG4gIHR5cGU6ICdhY3Rpb25jYWJsZSc7XG4gIGNoYW5uZWw/OiBzdHJpbmc7XG4gIGFjdGlvbj86IHN0cmluZztcbiAgZGV0YWlscz86IGFueTtcbn1cblxuLy8gQXN5bmNKb2IgZXJyb3IgaW5mb1xuaW50ZXJmYWNlIEFzeW5jSm9iRXJyb3JJbmZvIGV4dGVuZHMgQmFzZUVycm9ySW5mbyB7XG4gIHR5cGU6ICdhc3luY2pvYic7XG4gIGpvYl9jbGFzcz86IHN0cmluZztcbiAgam9iX2lkPzogc3RyaW5nO1xuICBxdWV1ZT86IHN0cmluZztcbiAgZXhjZXB0aW9uX2NsYXNzPzogc3RyaW5nO1xuICBiYWNrdHJhY2U/OiBzdHJpbmc7XG4gIGRldGFpbHM/OiBhbnk7XG59XG5cbi8vIE1hbnVhbCBlcnJvciBpbmZvXG5pbnRlcmZhY2UgTWFudWFsRXJyb3JJbmZvIGV4dGVuZHMgQmFzZUVycm9ySW5mbyB7XG4gIHR5cGU6ICdtYW51YWwnO1xuICBba2V5OiBzdHJpbmddOiBhbnk7IC8vIEFsbG93IGFkZGl0aW9uYWwgY29udGV4dCBwcm9wZXJ0aWVzXG59XG5cbi8vIFN0aW11bHVzIGVycm9yIGluZm9cbmludGVyZmFjZSBTdGltdWx1c0Vycm9ySW5mbyBleHRlbmRzIEJhc2VFcnJvckluZm8ge1xuICB0eXBlOiAnc3RpbXVsdXMnO1xuICBtaXNzaW5nQ29udHJvbGxlcnM/OiBzdHJpbmdbXTtcbiAgbWlzc2luZ1RhcmdldHM/OiBzdHJpbmdbXTtcbiAgb3V0T2ZTY29wZVRhcmdldHM/OiBzdHJpbmdbXTtcbiAgc3VnZ2VzdGlvbj86IHN0cmluZztcbiAgZGV0YWlscz86IGFueTtcbiAgc3ViVHlwZT86ICdtaXNzaW5nLWNvbnRyb2xsZXInIHwgJ3Njb3BlLWVycm9yJyB8ICdwb3NpdGlvbmluZy1pc3N1ZXMnIHwgJ2FjdGlvbi1jbGljaycgfCAnbWlzc2luZy10YXJnZXQnIHwgJ21pc3NpbmctYWN0aW9uJyB8ICdtZXRob2Qtbm90LWZvdW5kJyB8ICd0YXJnZXQtc2NvcGUtZXJyb3InO1xuICBjb250cm9sbGVyTmFtZT86IHN0cmluZztcbiAgYWN0aW9uPzogc3RyaW5nO1xuICBtZXRob2ROYW1lPzogc3RyaW5nO1xuICBlbGVtZW50SW5mbz86IGFueTtcbiAgcG9zaXRpb25pbmdJc3N1ZXM/OiBzdHJpbmdbXTtcbn1cblxuLy8gVW5pb24gdHlwZSBmb3IgYWxsIHBvc3NpYmxlIGVycm9yIGluZm8gdHlwZXNcbnR5cGUgRXJyb3JJbmZvID0gSmF2YVNjcmlwdEVycm9ySW5mbyB8IFByb21pc2VFcnJvckluZm8gfCBIdHRwRXJyb3JJbmZvIHwgQWN0aW9uQ2FibGVFcnJvckluZm8gfCBBc3luY0pvYkVycm9ySW5mbyB8IE1hbnVhbEVycm9ySW5mbyB8IFN0aW11bHVzRXJyb3JJbmZvO1xuXG4vLyBVbmlmaWVkIGVycm9yIGRldGFpbCBjb25maWd1cmF0aW9uIHN5c3RlbVxuaW50ZXJmYWNlIEVycm9yRGV0YWlsQ29uZmlnIHtcbiAgaHRtbEZvcm1hdHRlcjogKHZhbHVlOiBhbnksIGtleTogc3RyaW5nKSA9PiBzdHJpbmc7XG4gIHRleHRGb3JtYXR0ZXI6ICh2YWx1ZTogYW55LCBrZXk6IHN0cmluZykgPT4gc3RyaW5nO1xuICBsYWJlbDogc3RyaW5nO1xuICBwcmlvcml0eT86IG51bWJlcjsgLy8gSGlnaGVyIHByaW9yaXR5IGZpZWxkcyBhcHBlYXIgZmlyc3RcbiAgY29uZGl0aW9uPzogKGVycm9yOiBTdG9yZWRFcnJvcikgPT4gYm9vbGVhbjsgLy8gT3B0aW9uYWwgY29uZGl0aW9uIHRvIHNob3cgdGhpcyBmaWVsZFxufVxuXG5pbnRlcmZhY2UgRXJyb3JUeXBlQ29uZmlnIHtcbiAgaWNvbjogc3RyaW5nO1xuICBmaWVsZHM6IHsgW2tleTogc3RyaW5nXTogRXJyb3JEZXRhaWxDb25maWcgfTtcbn1cblxuLy8gQ2VudHJhbGl6ZWQgZXJyb3IgdHlwZSBjb25maWd1cmF0aW9uc1xuY29uc3QgRVJST1JfVFlQRV9DT05GSUdTOiB7IFtrZXk6IHN0cmluZ106IEVycm9yVHlwZUNvbmZpZyB9ID0ge1xuICBqYXZhc2NyaXB0OiB7XG4gICAgaWNvbjogJ1x1MjZBMFx1RkUwRicsXG4gICAgZmllbGRzOiB7XG4gICAgICBmaWxlbmFtZToge1xuICAgICAgICBsYWJlbDogJ0ZpbGUnLFxuICAgICAgICBwcmlvcml0eTogMTAsXG4gICAgICAgIGh0bWxGb3JtYXR0ZXI6ICh2YWx1ZTogc3RyaW5nKSA9PiBgPGRpdiBjbGFzcz1cIm15LTFcIj48c3Ryb25nPkZpbGU6PC9zdHJvbmc+ICR7dmFsdWV9PC9kaXY+YCxcbiAgICAgICAgdGV4dEZvcm1hdHRlcjogKHZhbHVlOiBzdHJpbmcpID0+IGBGaWxlOiAke3ZhbHVlfWBcbiAgICAgIH0sXG4gICAgICBsaW5lbm86IHtcbiAgICAgICAgbGFiZWw6ICdMaW5lJyxcbiAgICAgICAgcHJpb3JpdHk6IDksXG4gICAgICAgIGh0bWxGb3JtYXR0ZXI6ICh2YWx1ZTogbnVtYmVyKSA9PiBgPGRpdiBjbGFzcz1cIm1iLTFcIj48c3Ryb25nPkxpbmU6PC9zdHJvbmc+ICR7dmFsdWV9PC9kaXY+YCxcbiAgICAgICAgdGV4dEZvcm1hdHRlcjogKHZhbHVlOiBudW1iZXIpID0+IGBMaW5lOiAke3ZhbHVlfWBcbiAgICAgIH0sXG4gICAgICAnZXJyb3Iuc3RhY2snOiB7XG4gICAgICAgIGxhYmVsOiAnU3RhY2sgVHJhY2UnLFxuICAgICAgICBwcmlvcml0eTogMSxcbiAgICAgICAgY29uZGl0aW9uOiAoZXJyb3IpID0+IGVycm9yLmVycm9yPy5zdGFjayxcbiAgICAgICAgaHRtbEZvcm1hdHRlcjogKHZhbHVlOiBzdHJpbmcpID0+IHtcbiAgICAgICAgICBjb25zdCBwcmVDbGFzcyA9ICd0ZXh0LXhzIGJnLWdyYXktODAwIHAtMyByb3VuZGVkIG92ZXJmbG93LXgtYXV0byB3aGl0ZXNwYWNlLXByZS13cmFwIGxlYWRpbmctcmVsYXhlZCc7XG4gICAgICAgICAgcmV0dXJuIGA8ZGl2IGNsYXNzPVwiXCI+PGRpdiBjbGFzcz1cIm1iLTFcIj48c3Ryb25nPlN0YWNrIFRyYWNlOjwvc3Ryb25nPjwvZGl2PjxwcmUgY2xhc3M9XCIke3ByZUNsYXNzfVwiPiR7dmFsdWV9PC9wcmU+PC9kaXY+YDtcbiAgICAgICAgfSxcbiAgICAgICAgdGV4dEZvcm1hdHRlcjogKHZhbHVlOiBzdHJpbmcpID0+IGBTdGFjayBUcmFjZTpcXG4ke3ZhbHVlfWBcbiAgICAgIH1cbiAgICB9XG4gIH0sXG4gIGludGVyYWN0aW9uOiB7XG4gICAgaWNvbjogJ1x1RDgzRFx1REQzNCcsXG4gICAgZmllbGRzOiB7XG4gICAgICBmaWxlbmFtZToge1xuICAgICAgICBsYWJlbDogJ0ZpbGUnLFxuICAgICAgICBwcmlvcml0eTogMTAsXG4gICAgICAgIGh0bWxGb3JtYXR0ZXI6ICh2YWx1ZTogc3RyaW5nKSA9PiBgPGRpdiBjbGFzcz1cIm1iLTFcIj48c3Ryb25nPkZpbGU6PC9zdHJvbmc+ICR7dmFsdWV9PC9kaXY+YCxcbiAgICAgICAgdGV4dEZvcm1hdHRlcjogKHZhbHVlOiBzdHJpbmcpID0+IGBGaWxlOiAke3ZhbHVlfWBcbiAgICAgIH0sXG4gICAgICBsaW5lbm86IHtcbiAgICAgICAgbGFiZWw6ICdMaW5lJyxcbiAgICAgICAgcHJpb3JpdHk6IDksXG4gICAgICAgIGh0bWxGb3JtYXR0ZXI6ICh2YWx1ZTogbnVtYmVyKSA9PiBgPGRpdiBjbGFzcz1cIm1iLTFcIj48c3Ryb25nPkxpbmU6PC9zdHJvbmc+ICR7dmFsdWV9PC9kaXY+YCxcbiAgICAgICAgdGV4dEZvcm1hdHRlcjogKHZhbHVlOiBudW1iZXIpID0+IGBMaW5lOiAke3ZhbHVlfWBcbiAgICAgIH1cbiAgICB9XG4gIH0sXG4gIGh0dHA6IHtcbiAgICBpY29uOiAnXHVEODNDXHVERjEwJyxcbiAgICBmaWVsZHM6IHtcbiAgICAgIG1ldGhvZDoge1xuICAgICAgICBsYWJlbDogJ01ldGhvZCcsXG4gICAgICAgIHByaW9yaXR5OiAxMCxcbiAgICAgICAgaHRtbEZvcm1hdHRlcjogKHZhbHVlOiBzdHJpbmcpID0+IGA8ZGl2IGNsYXNzPVwibWItMVwiPjxzdHJvbmc+TWV0aG9kOjwvc3Ryb25nPiAke3ZhbHVlfTwvZGl2PmAsXG4gICAgICAgIHRleHRGb3JtYXR0ZXI6ICh2YWx1ZTogc3RyaW5nKSA9PiBgTWV0aG9kOiAke3ZhbHVlfWBcbiAgICAgIH0sXG4gICAgICBzdGF0dXM6IHtcbiAgICAgICAgbGFiZWw6ICdTdGF0dXMgQ29kZScsXG4gICAgICAgIHByaW9yaXR5OiA5LFxuICAgICAgICBodG1sRm9ybWF0dGVyOiAodmFsdWU6IG51bWJlcikgPT4gYDxkaXYgY2xhc3M9XCJtYi0xXCI+PHN0cm9uZz5TdGF0dXMgQ29kZTo8L3N0cm9uZz4gJHt2YWx1ZX08L2Rpdj5gLFxuICAgICAgICB0ZXh0Rm9ybWF0dGVyOiAodmFsdWU6IG51bWJlcikgPT4gYFN0YXR1cyBDb2RlOiAke3ZhbHVlfWBcbiAgICAgIH0sXG4gICAgICBqc29uRXJyb3I6IHtcbiAgICAgICAgbGFiZWw6ICdKU09OIEVycm9yIERldGFpbHMnLFxuICAgICAgICBwcmlvcml0eTogNSxcbiAgICAgICAgY29uZGl0aW9uOiAoZXJyb3IpID0+ICEhZXJyb3IuanNvbkVycm9yLFxuICAgICAgICBodG1sRm9ybWF0dGVyOiAodmFsdWU6IGFueSkgPT4ge1xuICAgICAgICAgIGNvbnN0IHByZUNsYXNzID0gJ3RleHQteHMgYmctZ3JheS04MDAgcC0zIHJvdW5kZWQgb3ZlcmZsb3cteC1hdXRvIHdoaXRlc3BhY2UtcHJlLXdyYXAgbGVhZGluZy1yZWxheGVkJztcbiAgICAgICAgICByZXR1cm4gYDxkaXYgY2xhc3M9XCJtYi0zXCI+PGRpdiBjbGFzcz1cIm1iLTFcIj48c3Ryb25nPkpTT04gRXJyb3IgRGV0YWlsczo8L3N0cm9uZz48L2Rpdj48cHJlIGNsYXNzPVwiJHtwcmVDbGFzc31cIj4ke0pTT04uc3RyaW5naWZ5KHZhbHVlLCBudWxsLCAyKX08L3ByZT48L2Rpdj5gO1xuICAgICAgICB9LFxuICAgICAgICB0ZXh0Rm9ybWF0dGVyOiAodmFsdWU6IGFueSkgPT4gYEpTT04gRXJyb3IgRGV0YWlsczpcXG4ke0pTT04uc3RyaW5naWZ5KHZhbHVlLCBudWxsLCAyKX1gXG4gICAgICB9XG4gICAgfVxuICB9LFxuICBwcm9taXNlOiB7XG4gICAgaWNvbjogJ1x1MjZBMScsXG4gICAgZmllbGRzOiB7XG4gICAgICAnZXJyb3Iuc3RhY2snOiB7XG4gICAgICAgIGxhYmVsOiAnU3RhY2sgVHJhY2UnLFxuICAgICAgICBwcmlvcml0eTogMSxcbiAgICAgICAgY29uZGl0aW9uOiAoZXJyb3IpID0+IGVycm9yLmVycm9yPy5zdGFjayxcbiAgICAgICAgaHRtbEZvcm1hdHRlcjogKHZhbHVlOiBzdHJpbmcpID0+IHtcbiAgICAgICAgICBjb25zdCBwcmVDbGFzcyA9ICd0ZXh0LXhzIGJnLWdyYXktODAwIHAtMyByb3VuZGVkIG92ZXJmbG93LXgtYXV0byB3aGl0ZXNwYWNlLXByZS13cmFwIGxlYWRpbmctcmVsYXhlZCc7XG4gICAgICAgICAgcmV0dXJuIGA8ZGl2IGNsYXNzPVwibWItM1wiPjxkaXYgY2xhc3M9XCJtYi0xXCI+PHN0cm9uZz5TdGFjayBUcmFjZTo8L3N0cm9uZz48L2Rpdj48cHJlIGNsYXNzPVwiJHtwcmVDbGFzc31cIj4ke3ZhbHVlfTwvcHJlPjwvZGl2PmA7XG4gICAgICAgIH0sXG4gICAgICAgIHRleHRGb3JtYXR0ZXI6ICh2YWx1ZTogc3RyaW5nKSA9PiBgU3RhY2sgVHJhY2U6XFxuJHt2YWx1ZX1gXG4gICAgICB9XG4gICAgfVxuICB9LFxuICBhY3Rpb25jYWJsZToge1xuICAgIGljb246ICdcdUQ4M0RcdUREMEMnLFxuICAgIGZpZWxkczoge1xuICAgICAgY2hhbm5lbDoge1xuICAgICAgICBsYWJlbDogJ0NoYW5uZWwnLFxuICAgICAgICBwcmlvcml0eTogMTAsXG4gICAgICAgIGh0bWxGb3JtYXR0ZXI6ICh2YWx1ZTogc3RyaW5nKSA9PiBgPGRpdiBjbGFzcz1cIm1iLTFcIj48c3Ryb25nPkNoYW5uZWw6PC9zdHJvbmc+ICR7dmFsdWV9PC9kaXY+YCxcbiAgICAgICAgdGV4dEZvcm1hdHRlcjogKHZhbHVlOiBzdHJpbmcpID0+IGBDaGFubmVsOiAke3ZhbHVlfWBcbiAgICAgIH0sXG4gICAgICBhY3Rpb246IHtcbiAgICAgICAgbGFiZWw6ICdBY3Rpb24nLFxuICAgICAgICBwcmlvcml0eTogOSxcbiAgICAgICAgaHRtbEZvcm1hdHRlcjogKHZhbHVlOiBzdHJpbmcpID0+IGA8ZGl2IGNsYXNzPVwibWItMVwiPjxzdHJvbmc+QWN0aW9uOjwvc3Ryb25nPiAke3ZhbHVlfTwvZGl2PmAsXG4gICAgICAgIHRleHRGb3JtYXR0ZXI6ICh2YWx1ZTogc3RyaW5nKSA9PiBgQWN0aW9uOiAke3ZhbHVlfWBcbiAgICAgIH0sXG4gICAgICBkZXRhaWxzOiB7XG4gICAgICAgIGxhYmVsOiAnQ2hhbm5lbCBFcnJvciBEZXRhaWxzJyxcbiAgICAgICAgcHJpb3JpdHk6IDUsXG4gICAgICAgIGNvbmRpdGlvbjogKGVycm9yKSA9PiAhIWVycm9yLmRldGFpbHMsXG4gICAgICAgIGh0bWxGb3JtYXR0ZXI6ICh2YWx1ZTogYW55KSA9PiB7XG4gICAgICAgICAgY29uc3QgcHJlQ2xhc3MgPSAndGV4dC14cyBiZy1ncmF5LTgwMCBwLTMgcm91bmRlZCBvdmVyZmxvdy14LWF1dG8gd2hpdGVzcGFjZS1wcmUtd3JhcCBsZWFkaW5nLXJlbGF4ZWQnO1xuICAgICAgICAgIHJldHVybiBgPGRpdiBjbGFzcz1cIm1iLTNcIj48ZGl2IGNsYXNzPVwibWItMVwiPjxzdHJvbmc+Q2hhbm5lbCBFcnJvciBEZXRhaWxzOjwvc3Ryb25nPjwvZGl2PjxwcmUgY2xhc3M9XCIke3ByZUNsYXNzfVwiPiR7SlNPTi5zdHJpbmdpZnkodmFsdWUsIG51bGwsIDIpfTwvcHJlPjwvZGl2PmA7XG4gICAgICAgIH0sXG4gICAgICAgIHRleHRGb3JtYXR0ZXI6ICh2YWx1ZTogYW55KSA9PiBgQ2hhbm5lbCBFcnJvciBEZXRhaWxzOlxcbiR7SlNPTi5zdHJpbmdpZnkodmFsdWUsIG51bGwsIDIpfWBcbiAgICAgIH1cbiAgICB9XG4gIH0sXG4gIHN0aW11bHVzOiB7XG4gICAgaWNvbjogJ1x1RDgzQ1x1REZBRicsXG4gICAgZmllbGRzOiB7XG4gICAgICBzdWJUeXBlOiB7XG4gICAgICAgIGxhYmVsOiAnU3RpbXVsdXMgRXJyb3IgVHlwZScsXG4gICAgICAgIHByaW9yaXR5OiAxMCxcbiAgICAgICAgaHRtbEZvcm1hdHRlcjogKHZhbHVlOiBzdHJpbmcpID0+IGA8ZGl2IGNsYXNzPVwibWItMVwiPjxzdHJvbmc+U3RpbXVsdXMgRXJyb3IgVHlwZTo8L3N0cm9uZz4gJHt2YWx1ZX08L2Rpdj5gLFxuICAgICAgICB0ZXh0Rm9ybWF0dGVyOiAodmFsdWU6IHN0cmluZykgPT4gYFN0aW11bHVzIEVycm9yIFR5cGU6ICR7dmFsdWV9YFxuICAgICAgfSxcbiAgICAgIGNvbnRyb2xsZXJOYW1lOiB7XG4gICAgICAgIGxhYmVsOiAnQ29udHJvbGxlcicsXG4gICAgICAgIHByaW9yaXR5OiA5LFxuICAgICAgICBodG1sRm9ybWF0dGVyOiAodmFsdWU6IHN0cmluZykgPT4gYDxkaXYgY2xhc3M9XCJtYi0xXCI+PHN0cm9uZz5Db250cm9sbGVyOjwvc3Ryb25nPiAke3ZhbHVlfTwvZGl2PmAsXG4gICAgICAgIHRleHRGb3JtYXR0ZXI6ICh2YWx1ZTogc3RyaW5nKSA9PiBgQ29udHJvbGxlcjogJHt2YWx1ZX1gXG4gICAgICB9LFxuICAgICAgYWN0aW9uOiB7XG4gICAgICAgIGxhYmVsOiAnQWN0aW9uJyxcbiAgICAgICAgcHJpb3JpdHk6IDgsXG4gICAgICAgIGh0bWxGb3JtYXR0ZXI6ICh2YWx1ZTogc3RyaW5nKSA9PiBgPGRpdiBjbGFzcz1cIm1iLTFcIj48c3Ryb25nPkFjdGlvbjo8L3N0cm9uZz4gJHt2YWx1ZX08L2Rpdj5gLFxuICAgICAgICB0ZXh0Rm9ybWF0dGVyOiAodmFsdWU6IHN0cmluZykgPT4gYEFjdGlvbjogJHt2YWx1ZX1gXG4gICAgICB9LFxuICAgICAgbWlzc2luZ0NvbnRyb2xsZXJzOiB7XG4gICAgICAgIGxhYmVsOiAnTWlzc2luZyBDb250cm9sbGVycycsXG4gICAgICAgIHByaW9yaXR5OiA3LFxuICAgICAgICBjb25kaXRpb246IChlcnJvcikgPT4gISEoZXJyb3IubWlzc2luZ0NvbnRyb2xsZXJzICYmIGVycm9yLm1pc3NpbmdDb250cm9sbGVycy5sZW5ndGggPiAwKSxcbiAgICAgICAgaHRtbEZvcm1hdHRlcjogKHZhbHVlOiBzdHJpbmdbXSkgPT4gYDxkaXYgY2xhc3M9XCJtYi0zXCI+PHN0cm9uZz5NaXNzaW5nIENvbnRyb2xsZXJzOjwvc3Ryb25nPiAke3ZhbHVlLmpvaW4oJywgJyl9PC9kaXY+YCxcbiAgICAgICAgdGV4dEZvcm1hdHRlcjogKHZhbHVlOiBzdHJpbmdbXSkgPT4gYE1pc3NpbmcgQ29udHJvbGxlcnM6ICR7dmFsdWUuam9pbignLCAnKX1gXG4gICAgICB9LFxuICAgICAgcG9zaXRpb25pbmdJc3N1ZXM6IHtcbiAgICAgICAgbGFiZWw6ICdQb3NpdGlvbmluZyBJc3N1ZXMnLFxuICAgICAgICBwcmlvcml0eTogNixcbiAgICAgICAgY29uZGl0aW9uOiAoZXJyb3IpID0+ICEhKGVycm9yLnBvc2l0aW9uaW5nSXNzdWVzICYmIGVycm9yLnBvc2l0aW9uaW5nSXNzdWVzLmxlbmd0aCA+IDApLFxuICAgICAgICBodG1sRm9ybWF0dGVyOiAodmFsdWU6IHN0cmluZ1tdKSA9PiB7XG4gICAgICAgICAgY29uc3QgdWxDbGFzcyA9ICd0ZXh0LXhzIGxpc3QtZGlzYyBsaXN0LWluc2lkZSBiZy1ncmF5LTgwMCBwLTMgcm91bmRlZCBzcGFjZS15LTEnO1xuICAgICAgICAgIGNvbnN0IGl0ZW1zID0gdmFsdWUubWFwKChpc3N1ZTogc3RyaW5nKSA9PiBgPGxpIGNsYXNzPVwibGVhZGluZy1yZWxheGVkXCI+JHtpc3N1ZX08L2xpPmApLmpvaW4oJycpO1xuICAgICAgICAgIHJldHVybiBgPGRpdiBjbGFzcz1cIm1iLTNcIj48ZGl2IGNsYXNzPVwibWItMVwiPjxzdHJvbmc+UG9zaXRpb25pbmcgSXNzdWVzOjwvc3Ryb25nPjwvZGl2Pjx1bCBjbGFzcz1cIiR7dWxDbGFzc31cIj4ke2l0ZW1zfTwvdWw+PC9kaXY+YDtcbiAgICAgICAgfSxcbiAgICAgICAgdGV4dEZvcm1hdHRlcjogKHZhbHVlOiBzdHJpbmdbXSkgPT4gYFBvc2l0aW9uaW5nIElzc3VlczpcXG4ke3ZhbHVlLm1hcCgoaXNzdWU6IHN0cmluZykgPT4gYCAgLSAke2lzc3VlfWApLmpvaW4oJ1xcbicpfWBcbiAgICAgIH0sXG4gICAgICBlbGVtZW50SW5mbzoge1xuICAgICAgICBsYWJlbDogJ0VsZW1lbnQgSW5mbycsXG4gICAgICAgIHByaW9yaXR5OiA1LFxuICAgICAgICBjb25kaXRpb246IChlcnJvcikgPT4gISFlcnJvci5lbGVtZW50SW5mbyxcbiAgICAgICAgaHRtbEZvcm1hdHRlcjogKHZhbHVlOiBhbnkpID0+IHtcbiAgICAgICAgICBjb25zdCBwcmVDbGFzcyA9ICd0ZXh0LXhzIGJnLWdyYXktODAwIHAtMyByb3VuZGVkIG92ZXJmbG93LXgtYXV0byB3aGl0ZXNwYWNlLXByZS13cmFwIGxlYWRpbmctcmVsYXhlZCc7XG4gICAgICAgICAgcmV0dXJuIGA8ZGl2IGNsYXNzPVwibWItM1wiPjxkaXYgY2xhc3M9XCJtYi0xXCI+PHN0cm9uZz5FbGVtZW50IEluZm86PC9zdHJvbmc+PC9kaXY+PHByZSBjbGFzcz1cIiR7cHJlQ2xhc3N9XCI+JHtKU09OLnN0cmluZ2lmeSh2YWx1ZSwgbnVsbCwgMil9PC9wcmU+PC9kaXY+YDtcbiAgICAgICAgfSxcbiAgICAgICAgdGV4dEZvcm1hdHRlcjogKHZhbHVlOiBhbnkpID0+IGBFbGVtZW50IEluZm86XFxuJHtKU09OLnN0cmluZ2lmeSh2YWx1ZSwgbnVsbCwgMil9YFxuICAgICAgfSxcbiAgICAgIHN1Z2dlc3Rpb246IHtcbiAgICAgICAgbGFiZWw6ICdcdUQ4M0RcdURDQTEgU3VnZ2VzdGlvbicsXG4gICAgICAgIHByaW9yaXR5OiAzLFxuICAgICAgICBodG1sRm9ybWF0dGVyOiAodmFsdWU6IHN0cmluZykgPT4ge1xuICAgICAgICAgIGNvbnN0IGRpdkNsYXNzID0gJ3RleHQtc20gYmctYmx1ZS05MDAgdGV4dC1ibHVlLTIwMCBwLTMgcm91bmRlZCBsZWFkaW5nLXJlbGF4ZWQnO1xuICAgICAgICAgIHJldHVybiBgPGRpdiBjbGFzcz1cIm1iLTNcIj48ZGl2IGNsYXNzPVwibWItMVwiPjxzdHJvbmc+XHVEODNEXHVEQ0ExIFN1Z2dlc3Rpb246PC9zdHJvbmc+PC9kaXY+PGRpdiBjbGFzcz1cIiR7ZGl2Q2xhc3N9XCI+JHt2YWx1ZX08L2Rpdj48L2Rpdj5gO1xuICAgICAgICB9LFxuICAgICAgICB0ZXh0Rm9ybWF0dGVyOiAodmFsdWU6IHN0cmluZykgPT4gYFN1Z2dlc3Rpb246ICR7dmFsdWV9YFxuICAgICAgfSxcbiAgICAgIGRldGFpbHM6IHtcbiAgICAgICAgbGFiZWw6ICdEZXRhaWxlZCBJbmZvcm1hdGlvbicsXG4gICAgICAgIHByaW9yaXR5OiAyLFxuICAgICAgICBjb25kaXRpb246IChlcnJvcikgPT4gISFlcnJvci5kZXRhaWxzLFxuICAgICAgICBodG1sRm9ybWF0dGVyOiAodmFsdWU6IGFueSkgPT4ge1xuICAgICAgICAgIGNvbnN0IHByZUNsYXNzID0gJ3RleHQteHMgYmctZ3JheS04MDAgcC0zIHJvdW5kZWQgb3ZlcmZsb3cteC1hdXRvIHdoaXRlc3BhY2UtcHJlLXdyYXAgbGVhZGluZy1yZWxheGVkJztcbiAgICAgICAgICByZXR1cm4gYDxkaXYgY2xhc3M9XCJtYi0zXCI+PGRpdiBjbGFzcz1cIm1iLTFcIj48c3Ryb25nPkRldGFpbGVkIEluZm9ybWF0aW9uOjwvc3Ryb25nPjwvZGl2PjxwcmUgY2xhc3M9XCIke3ByZUNsYXNzfVwiPiR7SlNPTi5zdHJpbmdpZnkodmFsdWUsIG51bGwsIDIpfTwvcHJlPjwvZGl2PmA7XG4gICAgICAgIH0sXG4gICAgICAgIHRleHRGb3JtYXR0ZXI6ICh2YWx1ZTogYW55KSA9PiBgRGV0YWlsZWQgSW5mb3JtYXRpb246XFxuJHtKU09OLnN0cmluZ2lmeSh2YWx1ZSwgbnVsbCwgMil9YFxuICAgICAgfVxuICAgIH1cbiAgfSxcbiAgYXN5bmNqb2I6IHtcbiAgICBpY29uOiAnXHUyNjk5XHVGRTBGJyxcbiAgICBmaWVsZHM6IHtcbiAgICAgIGpvYl9jbGFzczoge1xuICAgICAgICBsYWJlbDogJ0pvYiBDbGFzcycsXG4gICAgICAgIHByaW9yaXR5OiAxMCxcbiAgICAgICAgaHRtbEZvcm1hdHRlcjogKHZhbHVlOiBzdHJpbmcpID0+IGA8ZGl2IGNsYXNzPVwibWItMVwiPjxzdHJvbmc+Sm9iIENsYXNzOjwvc3Ryb25nPiAke3ZhbHVlfTwvZGl2PmAsXG4gICAgICAgIHRleHRGb3JtYXR0ZXI6ICh2YWx1ZTogc3RyaW5nKSA9PiBgSm9iIENsYXNzOiAke3ZhbHVlfWBcbiAgICAgIH0sXG4gICAgICBxdWV1ZToge1xuICAgICAgICBsYWJlbDogJ1F1ZXVlJyxcbiAgICAgICAgcHJpb3JpdHk6IDksXG4gICAgICAgIGh0bWxGb3JtYXR0ZXI6ICh2YWx1ZTogc3RyaW5nKSA9PiBgPGRpdiBjbGFzcz1cIm1iLTFcIj48c3Ryb25nPlF1ZXVlOjwvc3Ryb25nPiAke3ZhbHVlfTwvZGl2PmAsXG4gICAgICAgIHRleHRGb3JtYXR0ZXI6ICh2YWx1ZTogc3RyaW5nKSA9PiBgUXVldWU6ICR7dmFsdWV9YFxuICAgICAgfSxcbiAgICAgIGV4Y2VwdGlvbl9jbGFzczoge1xuICAgICAgICBsYWJlbDogJ0V4Y2VwdGlvbicsXG4gICAgICAgIHByaW9yaXR5OiA4LFxuICAgICAgICBodG1sRm9ybWF0dGVyOiAodmFsdWU6IHN0cmluZykgPT4gYDxkaXYgY2xhc3M9XCJtYi0xXCI+PHN0cm9uZz5FeGNlcHRpb246PC9zdHJvbmc+ICR7dmFsdWV9PC9kaXY+YCxcbiAgICAgICAgdGV4dEZvcm1hdHRlcjogKHZhbHVlOiBzdHJpbmcpID0+IGBFeGNlcHRpb246ICR7dmFsdWV9YFxuICAgICAgfSxcbiAgICAgIGJhY2t0cmFjZToge1xuICAgICAgICBsYWJlbDogJ0JhY2t0cmFjZScsXG4gICAgICAgIHByaW9yaXR5OiA1LFxuICAgICAgICBjb25kaXRpb246IChlcnJvcikgPT4gISFlcnJvci5iYWNrdHJhY2UsXG4gICAgICAgIGh0bWxGb3JtYXR0ZXI6ICh2YWx1ZTogc3RyaW5nKSA9PiB7XG4gICAgICAgICAgY29uc3QgcHJlQ2xhc3MgPSAndGV4dC14cyBiZy1ncmF5LTgwMCBwLTMgcm91bmRlZCBvdmVyZmxvdy14LWF1dG8gd2hpdGVzcGFjZS1wcmUtd3JhcCBsZWFkaW5nLXJlbGF4ZWQnO1xuICAgICAgICAgIHJldHVybiBgPGRpdiBjbGFzcz1cIm1iLTNcIj48ZGl2IGNsYXNzPVwibWItMVwiPjxzdHJvbmc+QmFja3RyYWNlOjwvc3Ryb25nPjwvZGl2PjxwcmUgY2xhc3M9XCIke3ByZUNsYXNzfVwiPiR7dmFsdWV9PC9wcmU+PC9kaXY+YDtcbiAgICAgICAgfSxcbiAgICAgICAgdGV4dEZvcm1hdHRlcjogKHZhbHVlOiBzdHJpbmcpID0+IGBCYWNrdHJhY2U6XFxuJHt2YWx1ZX1gXG4gICAgICB9XG4gICAgfVxuICB9LFxuICBtYW51YWw6IHtcbiAgICBpY29uOiAnXHVEODNEXHVEQ0REJyxcbiAgICBmaWVsZHM6IHtcbiAgICAgIC8vIE1hbnVhbCBlcnJvcnMgY2FuIGhhdmUgZHluYW1pYyBmaWVsZHMsIHNvIHdlJ2xsIGhhbmRsZSB0aGVtIGluIHRoZSBnZW5lcmljIGZvcm1hdHRlclxuICAgIH1cbiAgfVxufTtcblxuLy8gU3RvcmVkIGVycm9yIGludGVyZmFjZSAoaW5jbHVkZXMgYWRkaXRpb25hbCBwcm9wZXJ0aWVzIGFkZGVkIGJ5IHRoZSBoYW5kbGVyKVxuaW50ZXJmYWNlIFN0b3JlZEVycm9yIHtcbiAgaWQ6IHN0cmluZztcbiAgbWVzc2FnZTogc3RyaW5nO1xuICB0eXBlOiBFcnJvclR5cGU7XG4gIHRpbWVzdGFtcDogc3RyaW5nO1xuICBjb3VudDogbnVtYmVyO1xuICBsYXN0T2NjdXJyZWQ6IHN0cmluZztcbiAgLy8gT3B0aW9uYWwgcHJvcGVydGllcyB0aGF0IG1heSBleGlzdCBvbiBkaWZmZXJlbnQgZXJyb3IgdHlwZXNcbiAgZmlsZW5hbWU/OiBzdHJpbmc7XG4gIGxpbmVubz86IG51bWJlcjtcbiAgY29sbm8/OiBudW1iZXI7XG4gIGVycm9yPzogRXJyb3IgfCBhbnk7XG4gIHVybD86IHN0cmluZztcbiAgbWV0aG9kPzogc3RyaW5nO1xuICBzdGF0dXM/OiBudW1iZXI7XG4gIGpzb25FcnJvcj86IGFueTtcbiAgY2hhbm5lbD86IHN0cmluZztcbiAgYWN0aW9uPzogc3RyaW5nO1xuICBkZXRhaWxzPzogYW55O1xuICBtaXNzaW5nQ29udHJvbGxlcnM/OiBzdHJpbmdbXTtcbiAgc3VnZ2VzdGlvbj86IHN0cmluZztcbiAgW2tleTogc3RyaW5nXTogYW55OyAvLyBBbGxvdyBhZGRpdGlvbmFsIHByb3BlcnRpZXMgZm9yIG1hbnVhbCBlcnJvcnNcbn1cblxuLy8gRXJyb3IgY291bnRzIGludGVyZmFjZVxuaW50ZXJmYWNlIEVycm9yQ291bnRzIHtcbiAgamF2YXNjcmlwdDogbnVtYmVyO1xuICBpbnRlcmFjdGlvbjogbnVtYmVyO1xuICBwcm9taXNlOiBudW1iZXI7XG4gIGh0dHA6IG51bWJlcjtcbiAgYWN0aW9uY2FibGU6IG51bWJlcjtcbiAgYXN5bmNqb2I6IG51bWJlcjtcbiAgbWFudWFsPzogbnVtYmVyO1xuICBzdGltdWx1cz86IG51bWJlcjtcbn1cblxuY2xhc3MgRXJyb3JIYW5kbGVyIHtcbiAgcHJpdmF0ZSBlcnJvcnM6IFN0b3JlZEVycm9yW10gPSBbXTtcbiAgcHJpdmF0ZSBtYXhFcnJvcnM6IG51bWJlciA9IDUwO1xuICBwcml2YXRlIGlzRXhwYW5kZWQ6IGJvb2xlYW4gPSBmYWxzZTtcbiAgcHJpdmF0ZSBzdGF0dXNCYXI6IEhUTUxFbGVtZW50IHwgbnVsbCA9IG51bGw7XG4gIHByaXZhdGUgZXJyb3JMaXN0OiBIVE1MRWxlbWVudCB8IG51bGwgPSBudWxsO1xuICBwcml2YXRlIGlzSW50ZXJhY3Rpb25FcnJvcjogYm9vbGVhbiA9IGZhbHNlO1xuICBwcml2YXRlIGVycm9yQ291bnRzOiBFcnJvckNvdW50cyA9IHtcbiAgICBqYXZhc2NyaXB0OiAwLFxuICAgIGludGVyYWN0aW9uOiAwLFxuICAgIHByb21pc2U6IDAsXG4gICAgaHR0cDogMCxcbiAgICBhY3Rpb25jYWJsZTogMCxcbiAgICBhc3luY2pvYjogMCxcbiAgICBtYW51YWw6IDAsXG4gICAgc3RpbXVsdXM6IDBcbiAgfTtcbiAgcHJpdmF0ZSByZWNlbnRFcnJvcnNEZWJvdW5jZTogTWFwPHN0cmluZywgbnVtYmVyPiA9IG5ldyBNYXAoKTtcbiAgcHJpdmF0ZSBkZWJvdW5jZVRpbWU6IG51bWJlciA9IDEwMDA7XG4gIHByaXZhdGUgdWlSZWFkeTogYm9vbGVhbiA9IGZhbHNlO1xuICBwcml2YXRlIHBlbmRpbmdVSVVwZGF0ZXM6IGJvb2xlYW4gPSBmYWxzZTtcbiAgcHJpdmF0ZSBoYXNTaG93bkZpcnN0RXJyb3I6IGJvb2xlYW4gPSBmYWxzZTtcbiAgcHJpdmF0ZSBsYXN0SW50ZXJhY3Rpb25UaW1lOiBudW1iZXIgPSAwO1xuICBwcml2YXRlIG9yaWdpbmFsQ29uc29sZUVycm9yOiB0eXBlb2YgY29uc29sZS5lcnJvcjtcbiAgcHJpdmF0ZSBzb3VyY2VNYXBDYWNoZTogTWFwPHN0cmluZywgU291cmNlTWFwQ29uc3VtZXI+ID0gbmV3IE1hcCgpO1xuICBwcml2YXRlIHNvdXJjZU1hcFBlbmRpbmc6IE1hcDxzdHJpbmcsIFByb21pc2U8U291cmNlTWFwQ29uc3VtZXIgfCBudWxsPj4gPSBuZXcgTWFwKCk7XG4gIHByaXZhdGUgbGFzdFVzZXJBY3Rpb246IHtcbiAgICB0aW1lc3RhbXA6IG51bWJlcjtcbiAgICB0eXBlOiBzdHJpbmc7XG4gICAgZWxlbWVudDogc3RyaW5nO1xuICAgIHRleHQ/OiBzdHJpbmc7XG4gICAgc3RpbXVsdXNBY3Rpb24/OiBzdHJpbmc7XG4gICAgc3RpbXVsdXNDb250cm9sbGVyPzogc3RyaW5nO1xuICB9IHwgbnVsbCA9IG51bGw7XG5cbiAgY29uc3RydWN0b3IoKSB7XG4gICAgLy8gU2F2ZSBvcmlnaW5hbCBjb25zb2xlLmVycm9yIGJlZm9yZSBhbnkgaW50ZXJjZXB0aW9uXG4gICAgdGhpcy5vcmlnaW5hbENvbnNvbGVFcnJvciA9IGNvbnNvbGUuZXJyb3IuYmluZChjb25zb2xlKTtcbiAgICB0aGlzLmluaXQoKTtcbiAgfVxuXG4gIGluaXQoKSB7XG4gICAgLy8gU2V0dXAgZXJyb3IgaGFuZGxlcnMgaW1tZWRpYXRlbHlcbiAgICB0aGlzLnNldHVwR2xvYmFsRXJyb3JIYW5kbGVycygpO1xuICAgIHRoaXMuc2V0dXBJbnRlcmFjdGlvblRyYWNraW5nKCk7XG4gICAgdGhpcy5zZXR1cFR1cmJvSGFuZGxlcnMoKTtcblxuICAgIC8vIERlZmVyIFVJIGNyZWF0aW9uIHVudGlsIERPTSBpcyByZWFkeVxuICAgIGlmIChkb2N1bWVudC5yZWFkeVN0YXRlID09PSAnbG9hZGluZycpIHtcbiAgICAgIGRvY3VtZW50LmFkZEV2ZW50TGlzdGVuZXIoJ0RPTUNvbnRlbnRMb2FkZWQnLCAoKSA9PiB0aGlzLmluaXRVSSgpKTtcbiAgICB9IGVsc2Uge1xuICAgICAgdGhpcy5pbml0VUkoKTtcbiAgICB9XG4gIH1cblxuICBzZXR1cFR1cmJvSGFuZGxlcnMoKSB7XG4gICAgLy8gUHJlc2VydmUgc3RhdHVzIGJhciBkdXJpbmcgVHVyYm8gbmF2aWdhdGlvblxuICAgIGRvY3VtZW50LmFkZEV2ZW50TGlzdGVuZXIoJ3R1cmJvOmJlZm9yZS1yZW5kZXInLCAoZXZlbnQ6IGFueSkgPT4ge1xuICAgICAgaWYgKHRoaXMuc3RhdHVzQmFyICYmIHRoaXMuc3RhdHVzQmFyLnBhcmVudE5vZGUpIHtcbiAgICAgICAgLy8gUmVtb3ZlIHN0YXR1cyBiYXIgZnJvbSBvbGQgYm9keSBiZWZvcmUgcmVuZGVyXG4gICAgICAgIHRoaXMuc3RhdHVzQmFyLnJlbW92ZSgpO1xuICAgICAgfVxuICAgIH0pO1xuXG4gICAgLy8gUmUtYXBwZW5kIHN0YXR1cyBiYXIgYWZ0ZXIgcmVuZGVyIGNvbXBsZXRlc1xuICAgIGRvY3VtZW50LmFkZEV2ZW50TGlzdGVuZXIoJ3R1cmJvOnJlbmRlcicsICgpID0+IHtcbiAgICAgIGlmICh0aGlzLnN0YXR1c0JhciAmJiAhZG9jdW1lbnQuZ2V0RWxlbWVudEJ5SWQoJ2pzLWVycm9yLXN0YXR1cy1iYXInKSkge1xuICAgICAgICBkb2N1bWVudC5ib2R5LmFwcGVuZENoaWxkKHRoaXMuc3RhdHVzQmFyKTtcbiAgICAgIH1cbiAgICB9KTtcbiAgfVxuXG4gIGluaXRVSSgpIHtcbiAgICAvLyBQcmV2ZW50IHJlLWluaXRpYWxpemF0aW9uXG4gICAgaWYgKHRoaXMudWlSZWFkeSkge1xuICAgICAgcmV0dXJuO1xuICAgIH1cblxuICAgIGNvbnNvbGUubG9nKCdbRXJyb3JIYW5kbGVyXSBJbml0aWFsaXppbmcgVUknKTtcbiAgICB0aGlzLmNyZWF0ZVN0YXR1c0JhcigpO1xuICAgIHRoaXMudWlSZWFkeSA9IHRydWU7XG4gICAgdGhpcy51cGRhdGVTdGF0dXNCYXIoKTtcblxuICAgIC8vIElmIHRoZXJlIHdlcmUgZXJyb3JzIGJlZm9yZSBVSSB3YXMgcmVhZHksIHVwZGF0ZSBub3dcbiAgICBpZiAodGhpcy5wZW5kaW5nVUlVcGRhdGVzKSB7XG4gICAgICB0aGlzLnVwZGF0ZUVycm9yTGlzdCgpO1xuICAgICAgdGhpcy5zaG93U3RhdHVzQmFyKCk7XG4gICAgICB0aGlzLnBlbmRpbmdVSVVwZGF0ZXMgPSBmYWxzZTtcbiAgICB9XG4gIH1cblxuICBjcmVhdGVTdGF0dXNCYXIoKSB7XG4gICAgLy8gQ3JlYXRlIHBlcnNpc3RlbnQgYm90dG9tIHN0YXR1cyBiYXJcbiAgICBjb25zdCBzdGF0dXNCYXIgPSBkb2N1bWVudC5jcmVhdGVFbGVtZW50KCdkaXYnKTtcbiAgICBzdGF0dXNCYXIuaWQgPSAnanMtZXJyb3Itc3RhdHVzLWJhcic7XG4gICAgc3RhdHVzQmFyLmNsYXNzTmFtZSA9ICdmaXhlZCBib3R0b20tMCBsZWZ0LTAgcmlnaHQtMCBiZy1ncmF5LTkwMCB0ZXh0LXdoaXRlIHotNTAgYm9yZGVyLXQgYm9yZGVyLWdyYXktNzAwIHRyYW5zaXRpb24tYWxsIGR1cmF0aW9uLTMwMCc7XG4gICAgc3RhdHVzQmFyLnN0eWxlLmRpc3BsYXkgPSAnbm9uZSc7IC8vIEluaXRpYWxseSBoaWRkZW4gdW50aWwgZmlyc3QgZXJyb3JcblxuICAgIHN0YXR1c0Jhci5pbm5lckhUTUwgPSBgXG4gICAgICA8ZGl2IGNsYXNzPVwiZmxleCBpdGVtcy1jZW50ZXIganVzdGlmeS1iZXR3ZWVuIHB4LTQgcHktMiBoLTEwXCI+XG4gICAgICAgIDxkaXYgY2xhc3M9XCJmbGV4IGl0ZW1zLWNlbnRlciBzcGFjZS14LTRcIj5cbiAgICAgICAgICA8ZGl2IGlkPVwiZXJyb3Itc3VtbWFyeVwiIGNsYXNzPVwiZmxleCBpdGVtcy1jZW50ZXIgc3BhY2UteC0zIHRleHQtc21cIj5cbiAgICAgICAgICAgIDwhLS0gRXJyb3IgY291bnRzIHdpbGwgYmUgaW5zZXJ0ZWQgaGVyZSAtLT5cbiAgICAgICAgICA8L2Rpdj5cbiAgICAgICAgICA8ZGl2IGlkPVwiZXJyb3ItdGlwc1wiIGNsYXNzPVwicmVsYXRpdmVcIiBzdHlsZT1cImRpc3BsYXk6IG5vbmU7XCI+XG4gICAgICAgICAgICA8c3BhbiBjbGFzcz1cImN1cnNvci1oZWxwIHRleHQtZ3JheS01MDAgaG92ZXI6dGV4dC1ncmF5LTMwMCB0cmFuc2l0aW9uLWNvbG9ycyBkdXJhdGlvbi0yMDAgdGV4dC1zbSBvcGFjaXR5LTYwIGhvdmVyOm9wYWNpdHktMTAwXCI+XHVEODNEXHVEQ0ExPC9zcGFuPlxuICAgICAgICAgICAgPGRpdiBjbGFzcz1cImFic29sdXRlIGJvdHRvbS1mdWxsIGxlZnQtMS8yIHRyYW5zZm9ybSAtdHJhbnNsYXRlLXgtMS8yIG1iLTIgcHgtMyBweS0yIGJnLWdyYXktODAwIHRleHQtd2hpdGUgdGV4dC14c1xuICAgICAgICAgICAgICAgICAgICAgIHJvdW5kZWQtbGcgc2hhZG93LWxnIGJvcmRlciBib3JkZXItZ3JheS02MDAgd2hpdGVzcGFjZS1ub3dyYXAgb3BhY2l0eS0wIHBvaW50ZXItZXZlbnRzLW5vbmVcbiAgICAgICAgICAgICAgICAgICAgICB0cmFuc2l0aW9uLW9wYWNpdHkgZHVyYXRpb24tMjAwIHRvb2x0aXBcIj5cbiAgICAgICAgICAgICAgU2VuZCB0byBjaGF0Ym94IGZvciByZXBhaXIgKDkwJSBjYXNlcykgb3IgaWdub3JlIGlmIGJyb3dzZXIgZXh0ZW5zaW9uICgxMCUgY2FzZXMpXG4gICAgICAgICAgICAgIDxkaXYgY2xhc3M9XCJhYnNvbHV0ZSB0b3AtZnVsbCBsZWZ0LTEvMiB0cmFuc2Zvcm0gLXRyYW5zbGF0ZS14LTEvMiB3LTAgaC0wIGJvcmRlci1sLTQgYm9yZGVyLXItNCBib3JkZXItdC00XG4gICAgICAgICAgICAgICAgICAgICAgICBib3JkZXItdHJhbnNwYXJlbnQgYm9yZGVyLXQtZ3JheS04MDBcIj48L2Rpdj5cbiAgICAgICAgICAgIDwvZGl2PlxuICAgICAgICAgIDwvZGl2PlxuICAgICAgICA8L2Rpdj5cbiAgICAgICAgPGRpdiBjbGFzcz1cImZsZXggaXRlbXMtY2VudGVyIHNwYWNlLXgtMlwiPlxuICAgICAgICAgIDxidXR0b24gaWQ9XCJjb3B5LWFsbC1lcnJvcnNcIiBjbGFzcz1cInRleHQteWVsbG93LTQwMCBob3Zlcjp0ZXh0LXllbGxvdy0zMDAgdGV4dC1zbSBweC0yIHB5LTEgcm91bmRlZFwiIHN0eWxlPVwiZGlzcGxheTogbm9uZTtcIj5cbiAgICAgICAgICAgIENvcHkgRXJyb3JcbiAgICAgICAgICA8L2J1dHRvbj5cbiAgICAgICAgICA8YnV0dG9uIGlkPVwidG9nZ2xlLWVycm9yc1wiIGNsYXNzPVwidGV4dC1ibHVlLTQwMCBob3Zlcjp0ZXh0LWJsdWUtMzAwIHRleHQtc20gcHgtMiBweS0xIHJvdW5kZWRcIj5cbiAgICAgICAgICAgIDxzcGFuIGlkPVwidG9nZ2xlLXRleHRcIj5TaG93PC9zcGFuPlxuICAgICAgICAgICAgPHNwYW4gaWQ9XCJ0b2dnbGUtaWNvblwiPlx1MjE5MTwvc3Bhbj5cbiAgICAgICAgICA8L2J1dHRvbj5cbiAgICAgICAgICA8YnV0dG9uIGlkPVwiY2xlYXItYWxsLWVycm9yc1wiIGNsYXNzPVwidGV4dC1yZWQtNDAwIGhvdmVyOnRleHQtcmVkLTMwMCB0ZXh0LXNtIHB4LTIgcHktMSByb3VuZGVkXCI+XG4gICAgICAgICAgICBDbGVhclxuICAgICAgICAgIDwvYnV0dG9uPlxuICAgICAgICA8L2Rpdj5cbiAgICAgIDwvZGl2PlxuICAgICAgPGRpdiBpZD1cImVycm9yLWRldGFpbHNcIiBjbGFzcz1cImJvcmRlci10IGJvcmRlci1ncmF5LTcwMCBiZy1ncmF5LTgwMCBtYXgtaC02NCBvdmVyZmxvdy15LWF1dG9cIiBzdHlsZT1cImRpc3BsYXk6IG5vbmU7XCI+XG4gICAgICAgIDxkaXYgaWQ9XCJlcnJvci1saXN0XCIgY2xhc3M9XCJwLTQgc3BhY2UteS0yXCI+XG4gICAgICAgICAgPCEtLSBFcnJvciBsaXN0IHdpbGwgYmUgaW5zZXJ0ZWQgaGVyZSAtLT5cbiAgICAgICAgPC9kaXY+XG4gICAgICA8L2Rpdj5cbiAgICBgO1xuXG4gICAgZG9jdW1lbnQuYm9keS5hcHBlbmRDaGlsZChzdGF0dXNCYXIpO1xuICAgIHRoaXMuc3RhdHVzQmFyID0gc3RhdHVzQmFyO1xuICAgIHRoaXMuZXJyb3JMaXN0ID0gZG9jdW1lbnQuZ2V0RWxlbWVudEJ5SWQoJ2Vycm9yLWxpc3QnKTtcblxuICAgIHRoaXMuc2V0dXBTdGF0dXNCYXJFdmVudHMoKTtcbiAgfVxuXG4gIHNldHVwU3RhdHVzQmFyRXZlbnRzKCkge1xuICAgIC8vIFRvZ2dsZSBleHBhbmQvY29sbGFwc2VcbiAgICBkb2N1bWVudC5nZXRFbGVtZW50QnlJZCgndG9nZ2xlLWVycm9ycycpPy5hZGRFdmVudExpc3RlbmVyKCdjbGljaycsICgpID0+IHtcbiAgICAgIHRoaXMudG9nZ2xlRXJyb3JEZXRhaWxzKCk7XG4gICAgfSk7XG5cbiAgICAvLyBDb3B5IGFsbCBlcnJvcnNcbiAgICBkb2N1bWVudC5nZXRFbGVtZW50QnlJZCgnY29weS1hbGwtZXJyb3JzJyk/LmFkZEV2ZW50TGlzdGVuZXIoJ2NsaWNrJywgKCkgPT4ge1xuICAgICAgdGhpcy5jb3B5QWxsRXJyb3JzVG9DbGlwYm9hcmQoKTtcbiAgICB9KTtcblxuICAgIC8vIENsZWFyIGFsbCBlcnJvcnNcbiAgICBkb2N1bWVudC5nZXRFbGVtZW50QnlJZCgnY2xlYXItYWxsLWVycm9ycycpPy5hZGRFdmVudExpc3RlbmVyKCdjbGljaycsICgpID0+IHtcbiAgICAgIHRoaXMuY2xlYXJBbGxFcnJvcnMoKTtcbiAgICB9KTtcblxuICAgIC8vIFNldHVwIHRvb2x0aXAgaG92ZXIgZXZlbnRzXG4gICAgdGhpcy5zZXR1cFRvb2x0aXBFdmVudHMoKTtcbiAgfVxuXG4gIHNldHVwVG9vbHRpcEV2ZW50cygpIHtcbiAgICBjb25zdCB0aXBzQ29udGFpbmVyID0gZG9jdW1lbnQuZ2V0RWxlbWVudEJ5SWQoJ2Vycm9yLXRpcHMnKTtcbiAgICBpZiAoIXRpcHNDb250YWluZXIpIHJldHVybjtcblxuICAgIGNvbnN0IGljb24gPSB0aXBzQ29udGFpbmVyLnF1ZXJ5U2VsZWN0b3IoJ3NwYW4nKTtcbiAgICBjb25zdCB0b29sdGlwID0gdGlwc0NvbnRhaW5lci5xdWVyeVNlbGVjdG9yKCcudG9vbHRpcCcpO1xuXG4gICAgaWYgKGljb24gJiYgdG9vbHRpcCkge1xuICAgICAgLy8gU2hvdyB0b29sdGlwIG9uIGhvdmVyXG4gICAgICBpY29uLmFkZEV2ZW50TGlzdGVuZXIoJ21vdXNlZW50ZXInLCAoKSA9PiB7XG4gICAgICAgIHRvb2x0aXAuY2xhc3NMaXN0LnJlbW92ZSgnb3BhY2l0eS0wJywgJ3BvaW50ZXItZXZlbnRzLW5vbmUnKTtcbiAgICAgICAgdG9vbHRpcC5jbGFzc0xpc3QuYWRkKCdvcGFjaXR5LTEwMCcpO1xuICAgICAgfSk7XG5cbiAgICAgIC8vIEhpZGUgdG9vbHRpcCB3aGVuIG5vdCBob3ZlcmluZ1xuICAgICAgaWNvbi5hZGRFdmVudExpc3RlbmVyKCdtb3VzZWxlYXZlJywgKCkgPT4ge1xuICAgICAgICB0b29sdGlwLmNsYXNzTGlzdC5yZW1vdmUoJ29wYWNpdHktMTAwJyk7XG4gICAgICAgIHRvb2x0aXAuY2xhc3NMaXN0LmFkZCgnb3BhY2l0eS0wJywgJ3BvaW50ZXItZXZlbnRzLW5vbmUnKTtcbiAgICAgIH0pO1xuICAgIH1cbiAgfVxuXG4gIHRvZ2dsZUVycm9yRGV0YWlscygpIHtcbiAgICBjb25zdCBkZXRhaWxzID0gZG9jdW1lbnQuZ2V0RWxlbWVudEJ5SWQoJ2Vycm9yLWRldGFpbHMnKTtcbiAgICBjb25zdCB0b2dnbGVUZXh0ID0gZG9jdW1lbnQuZ2V0RWxlbWVudEJ5SWQoJ3RvZ2dsZS10ZXh0Jyk7XG4gICAgY29uc3QgdG9nZ2xlSWNvbiA9IGRvY3VtZW50LmdldEVsZW1lbnRCeUlkKCd0b2dnbGUtaWNvbicpO1xuXG4gICAgaWYgKCFkZXRhaWxzIHx8ICF0b2dnbGVUZXh0IHx8ICF0b2dnbGVJY29uKSByZXR1cm47XG5cbiAgICB0aGlzLmlzRXhwYW5kZWQgPSAhdGhpcy5pc0V4cGFuZGVkO1xuXG4gICAgaWYgKHRoaXMuaXNFeHBhbmRlZCkge1xuICAgICAgZGV0YWlscy5zdHlsZS5kaXNwbGF5ID0gJ2Jsb2NrJztcbiAgICAgIHRvZ2dsZVRleHQudGV4dENvbnRlbnQgPSAnSGlkZSc7XG4gICAgICB0b2dnbGVJY29uLnRleHRDb250ZW50ID0gJ1x1MjE5Myc7XG4gICAgfSBlbHNlIHtcbiAgICAgIGRldGFpbHMuc3R5bGUuZGlzcGxheSA9ICdub25lJztcbiAgICAgIHRvZ2dsZVRleHQudGV4dENvbnRlbnQgPSAnU2hvdyc7XG4gICAgICB0b2dnbGVJY29uLnRleHRDb250ZW50ID0gJ1x1MjE5MSc7XG4gICAgfVxuICB9XG5cbiAgcmVjb3JkVXNlckFjdGlvbihldmVudFR5cGU6IHN0cmluZywgZXZlbnQ6IEV2ZW50KSB7XG4gICAgY29uc3QgdGFyZ2V0ID0gZXZlbnQudGFyZ2V0IGFzIEhUTUxFbGVtZW50O1xuICAgIGlmICghdGFyZ2V0KSByZXR1cm47XG5cbiAgICAvLyBFeHRyYWN0IGVsZW1lbnQgaW5mb3JtYXRpb25cbiAgICBjb25zdCBlbGVtZW50UGFydHM6IHN0cmluZ1tdID0gW3RhcmdldC50YWdOYW1lLnRvTG93ZXJDYXNlKCldO1xuXG4gICAgaWYgKHRhcmdldC5pZCkge1xuICAgICAgZWxlbWVudFBhcnRzLnB1c2goYCMke3RhcmdldC5pZH1gKTtcbiAgICB9XG5cbiAgICBpZiAodGFyZ2V0LmNsYXNzTmFtZSAmJiB0eXBlb2YgdGFyZ2V0LmNsYXNzTmFtZSA9PT0gJ3N0cmluZycpIHtcbiAgICAgIGNvbnN0IGNsYXNzZXMgPSB0YXJnZXQuY2xhc3NOYW1lLnNwbGl0KCcgJykuZmlsdGVyKGMgPT4gYy50cmltKCkpO1xuICAgICAgaWYgKGNsYXNzZXMubGVuZ3RoID4gMCkge1xuICAgICAgICBlbGVtZW50UGFydHMucHVzaChgLiR7Y2xhc3Nlcy5zbGljZSgwLCAzKS5qb2luKCcuJyl9YCk7IC8vIE1heCAzIGNsYXNzZXNcbiAgICAgIH1cbiAgICB9XG5cbiAgICBjb25zdCBlbGVtZW50U2VsZWN0b3IgPSBlbGVtZW50UGFydHMuam9pbignJyk7XG5cbiAgICAvLyBFeHRyYWN0IHRleHQgY29udGVudCAobGltaXQgdG8gNTAgY2hhcnMsIHNraXAgZm9yIGlucHV0L2NoYW5nZSBldmVudHMpXG4gICAgbGV0IHRleHQ6IHN0cmluZyB8IHVuZGVmaW5lZDtcbiAgICBpZiAoZXZlbnRUeXBlICE9PSAnY2hhbmdlJyAmJiBldmVudFR5cGUgIT09ICdrZXlkb3duJykge1xuICAgICAgY29uc3QgdGV4dENvbnRlbnQgPSB0YXJnZXQudGV4dENvbnRlbnQ/LnRyaW0oKSB8fCAnJztcbiAgICAgIGlmICh0ZXh0Q29udGVudCAmJiB0ZXh0Q29udGVudC5sZW5ndGggPiAwKSB7XG4gICAgICAgIHRleHQgPSB0ZXh0Q29udGVudC5zdWJzdHJpbmcoMCwgNTApO1xuICAgICAgICBpZiAodGV4dENvbnRlbnQubGVuZ3RoID4gNTApIHRleHQgKz0gJy4uLic7XG4gICAgICB9XG4gICAgfVxuXG4gICAgLy8gRXh0cmFjdCBTdGltdWx1cyBhdHRyaWJ1dGVzXG4gICAgY29uc3Qgc3RpbXVsdXNBY3Rpb24gPSB0YXJnZXQuZ2V0QXR0cmlidXRlKCdkYXRhLWFjdGlvbicpIHx8IHVuZGVmaW5lZDtcbiAgICBjb25zdCBzdGltdWx1c0NvbnRyb2xsZXIgPSB0YXJnZXQuZ2V0QXR0cmlidXRlKCdkYXRhLWNvbnRyb2xsZXInKSB8fCB1bmRlZmluZWQ7XG5cbiAgICAvLyBFeHRyYWN0IGZvcm0gYWN0aW9uIG9yIGxpbmsgaHJlZlxuICAgIGxldCBhZGRpdGlvbmFsSW5mbyA9ICcnO1xuICAgIGlmICh0YXJnZXQudGFnTmFtZSA9PT0gJ0EnKSB7XG4gICAgICBjb25zdCBocmVmID0gdGFyZ2V0LmdldEF0dHJpYnV0ZSgnaHJlZicpO1xuICAgICAgaWYgKGhyZWYpIGFkZGl0aW9uYWxJbmZvID0gYCBocmVmPVwiJHtocmVmfVwiYDtcbiAgICB9IGVsc2UgaWYgKHRhcmdldC50YWdOYW1lID09PSAnRk9STScpIHtcbiAgICAgIGNvbnN0IGFjdGlvbiA9IHRhcmdldC5nZXRBdHRyaWJ1dGUoJ2FjdGlvbicpO1xuICAgICAgaWYgKGFjdGlvbikgYWRkaXRpb25hbEluZm8gPSBgIGFjdGlvbj1cIiR7YWN0aW9ufVwiYDtcbiAgICB9XG5cbiAgICB0aGlzLmxhc3RVc2VyQWN0aW9uID0ge1xuICAgICAgdGltZXN0YW1wOiBEYXRlLm5vdygpLFxuICAgICAgdHlwZTogZXZlbnRUeXBlLFxuICAgICAgZWxlbWVudDogZWxlbWVudFNlbGVjdG9yICsgYWRkaXRpb25hbEluZm8sXG4gICAgICB0ZXh0LFxuICAgICAgc3RpbXVsdXNBY3Rpb24sXG4gICAgICBzdGltdWx1c0NvbnRyb2xsZXJcbiAgICB9O1xuICB9XG5cbiAgc2V0dXBHbG9iYWxFcnJvckhhbmRsZXJzKCkge1xuICAgIC8vIEludGVyY2VwdCBjb25zb2xlLmVycm9yXG4gICAgY29uc29sZS5lcnJvciA9ICguLi5hcmdzOiBhbnlbXSkgPT4ge1xuICAgICAgLy8gQWx3YXlzIGNhbGwgb3JpZ2luYWwgY29uc29sZS5lcnJvciBmaXJzdFxuICAgICAgdGhpcy5vcmlnaW5hbENvbnNvbGVFcnJvciguLi5hcmdzKTtcblxuICAgICAgLy8gRXh0cmFjdCBhbmQgZm9ybWF0IGVycm9yIG1lc3NhZ2UgZnJvbSBhcmd1bWVudHNcbiAgICAgIGxldCBtZXNzYWdlID0gJyc7XG5cbiAgICAgIGlmIChhcmdzLmxlbmd0aCA9PT0gMCkgcmV0dXJuO1xuXG4gICAgICAvLyBDaGVjayBpZiBmaXJzdCBhcmd1bWVudCBpcyBhIGZvcm1hdCBzdHJpbmcgKGNvbnRhaW5zICVzLCAlbywgJWQsIGV0Yy4pXG4gICAgICBjb25zdCBmaXJzdEFyZyA9IGFyZ3NbMF07XG4gICAgICBpZiAodHlwZW9mIGZpcnN0QXJnID09PSAnc3RyaW5nJyAmJiAvJVtzb2RpZmNPXS8udGVzdChmaXJzdEFyZykpIHtcbiAgICAgICAgLy8gRm9ybWF0IHN0cmluZyBkZXRlY3RlZCAtIGFwcGx5IGJhc2ljIGZvcm1hdHRpbmdcbiAgICAgICAgbWVzc2FnZSA9IGZpcnN0QXJnO1xuICAgICAgICBsZXQgYXJnSW5kZXggPSAxO1xuXG4gICAgICAgIC8vIFJlcGxhY2UgZm9ybWF0IHNwZWNpZmllcnMgd2l0aCBhY3R1YWwgdmFsdWVzXG4gICAgICAgIG1lc3NhZ2UgPSBtZXNzYWdlLnJlcGxhY2UoLyVbc29kaWZjT10vZywgKG1hdGNoKSA9PiB7XG4gICAgICAgICAgaWYgKGFyZ0luZGV4ID49IGFyZ3MubGVuZ3RoKSByZXR1cm4gbWF0Y2g7XG4gICAgICAgICAgY29uc3QgYXJnID0gYXJnc1thcmdJbmRleCsrXTtcblxuICAgICAgICAgIGlmIChhcmcgaW5zdGFuY2VvZiBFcnJvcikge1xuICAgICAgICAgICAgcmV0dXJuIGFyZy5tZXNzYWdlO1xuICAgICAgICAgIH0gZWxzZSBpZiAodHlwZW9mIGFyZyA9PT0gJ29iamVjdCcpIHtcbiAgICAgICAgICAgIHRyeSB7XG4gICAgICAgICAgICAgIHJldHVybiBKU09OLnN0cmluZ2lmeShhcmcpO1xuICAgICAgICAgICAgfSBjYXRjaCB7XG4gICAgICAgICAgICAgIHJldHVybiBTdHJpbmcoYXJnKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICB9XG4gICAgICAgICAgcmV0dXJuIFN0cmluZyhhcmcpO1xuICAgICAgICB9KTtcbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIC8vIE5vIGZvcm1hdCBzdHJpbmcgLSBqb2luIGFsbCBhcmd1bWVudHNcbiAgICAgICAgbWVzc2FnZSA9IGFyZ3MubWFwKGFyZyA9PiB7XG4gICAgICAgICAgaWYgKGFyZyBpbnN0YW5jZW9mIEVycm9yKSB7XG4gICAgICAgICAgICByZXR1cm4gYXJnLm1lc3NhZ2U7XG4gICAgICAgICAgfSBlbHNlIGlmICh0eXBlb2YgYXJnID09PSAnb2JqZWN0Jykge1xuICAgICAgICAgICAgdHJ5IHtcbiAgICAgICAgICAgICAgcmV0dXJuIEpTT04uc3RyaW5naWZ5KGFyZyk7XG4gICAgICAgICAgICB9IGNhdGNoIHtcbiAgICAgICAgICAgICAgcmV0dXJuIFN0cmluZyhhcmcpO1xuICAgICAgICAgICAgfVxuICAgICAgICAgIH1cbiAgICAgICAgICByZXR1cm4gU3RyaW5nKGFyZyk7XG4gICAgICAgIH0pLmpvaW4oJyAnKTtcbiAgICAgIH1cblxuICAgICAgLy8gU2tpcCBpZiBtZXNzYWdlIGlzIGVtcHR5IG9yIHRyaXZpYWxcbiAgICAgIGlmICghbWVzc2FnZSB8fCBtZXNzYWdlLnRyaW0oKS5sZW5ndGggPT09IDApIHtcbiAgICAgICAgcmV0dXJuO1xuICAgICAgfVxuXG4gICAgICAvLyBDaGVjayBmb3IgZHVwbGljYXRlIHVzaW5nIHBhcnRpYWwgbWF0Y2hpbmdcbiAgICAgIGNvbnN0IGlzRHVwbGljYXRlID0gdGhpcy5lcnJvcnMuc29tZShlcnJvciA9PiB7XG4gICAgICAgIC8vIFJlbW92ZSBbY29uc29sZS5lcnJvcl0gcHJlZml4IGZvciBjb21wYXJpc29uXG4gICAgICAgIGNvbnN0IGV4aXN0aW5nTXNnID0gZXJyb3IubWVzc2FnZS5yZXBsYWNlKC9eXFxbY29uc29sZVxcLmVycm9yXFxdXFxzKi8sICcnKTtcbiAgICAgICAgY29uc3QgbmV3TXNnID0gbWVzc2FnZTtcblxuICAgICAgICAvLyBDb25zaWRlciBpdCBkdXBsaWNhdGUgaWYgb25lIG1lc3NhZ2UgY29udGFpbnMgdGhlIG90aGVyXG4gICAgICAgIGNvbnN0IGlzU2ltaWxhciA9IGV4aXN0aW5nTXNnLmluY2x1ZGVzKG5ld01zZykgfHwgbmV3TXNnLmluY2x1ZGVzKGV4aXN0aW5nTXNnKTtcbiAgICAgICAgY29uc3QgaXNSZWNlbnQgPSBEYXRlLm5vdygpIC0gbmV3IERhdGUoZXJyb3IubGFzdE9jY3VycmVkKS5nZXRUaW1lKCkgPCA1MDAwOyAvLyA1IHNlY29uZCB3aW5kb3dcblxuICAgICAgICByZXR1cm4gaXNTaW1pbGFyICYmIGlzUmVjZW50O1xuICAgICAgfSk7XG5cbiAgICAgIGlmICghaXNEdXBsaWNhdGUpIHtcbiAgICAgICAgLy8gQ3JlYXRlIEVycm9yIHRvIGNhcHR1cmUgc3RhY2sgdHJhY2UgaWYgbm90IGFscmVhZHkgcHJlc2VudFxuICAgICAgICBsZXQgZXJyb3JPYmogPSBhcmdzLmZpbmQoYXJnID0+IGFyZyBpbnN0YW5jZW9mIEVycm9yKTtcbiAgICAgICAgaWYgKCFlcnJvck9iaikge1xuICAgICAgICAgIGVycm9yT2JqID0gbmV3IEVycm9yKG1lc3NhZ2UpO1xuICAgICAgICAgIC8vIFJlbW92ZSBmaXJzdCAyIGxpbmVzIGZyb20gc3RhY2sgKEVycm9yIGNyZWF0aW9uIGFuZCBjb25zb2xlLmVycm9yIHdyYXBwZXIpXG4gICAgICAgICAgaWYgKGVycm9yT2JqLnN0YWNrKSB7XG4gICAgICAgICAgICBjb25zdCBzdGFja0xpbmVzID0gZXJyb3JPYmouc3RhY2suc3BsaXQoJ1xcbicpO1xuICAgICAgICAgICAgZXJyb3JPYmouc3RhY2sgPSBbc3RhY2tMaW5lc1swXSwgLi4uc3RhY2tMaW5lcy5zbGljZSgzKV0uam9pbignXFxuJyk7XG4gICAgICAgICAgfVxuICAgICAgICB9XG5cbiAgICAgICAgLy8gUmVwb3J0IHRvIGVycm9yIGhhbmRsZXIgd2l0aCBbY29uc29sZS5lcnJvcl0gcHJlZml4XG4gICAgICAgIHRoaXMuaGFuZGxlRXJyb3Ioe1xuICAgICAgICAgIG1lc3NhZ2U6IGBbY29uc29sZS5lcnJvcl0gJHttZXNzYWdlfWAsXG4gICAgICAgICAgdHlwZTogJ2phdmFzY3JpcHQnLFxuICAgICAgICAgIHRpbWVzdGFtcDogbmV3IERhdGUoKS50b0lTT1N0cmluZygpLFxuICAgICAgICAgIGVycm9yOiBlcnJvck9ialxuICAgICAgICB9KTtcbiAgICAgIH1cbiAgICB9O1xuXG4gICAgLy8gU2V0IHdpbmRvdy5vbmVycm9yIGZvciBjb21wYXRpYmlsaXR5IHdpdGggbGlicmFyaWVzIGxpa2UgU3RpbXVsdXMgdGhhdCBjaGVjayBmb3IgaXRzIGV4aXN0ZW5jZVxuICAgIGlmICghd2luZG93Lm9uZXJyb3IpIHtcbiAgICAgIHdpbmRvdy5vbmVycm9yID0gKG1lc3NhZ2U6IHN0cmluZyB8IEV2ZW50LCBzb3VyY2U/OiBzdHJpbmcsIGxpbmVubz86IG51bWJlciwgY29sbm8/OiBudW1iZXIsIGVycm9yPzogRXJyb3IpID0+IHtcbiAgICAgICAgdGhpcy5vcmlnaW5hbENvbnNvbGVFcnJvcignXHVEODNEXHVERDE0IHdpbmRvdy5vbmVycm9yIHRyaWdnZXJlZDonLCB7IG1lc3NhZ2UsIHNvdXJjZSwgbGluZW5vLCBjb2xubywgZXJyb3IgfSk7XG4gICAgICAgIHRoaXMuaGFuZGxlRXJyb3Ioe1xuICAgICAgICAgIG1lc3NhZ2U6IHR5cGVvZiBtZXNzYWdlID09PSAnc3RyaW5nJyA/IG1lc3NhZ2UgOiAnU2NyaXB0IGVycm9yJyxcbiAgICAgICAgICBmaWxlbmFtZTogc291cmNlLFxuICAgICAgICAgIGxpbmVubzogbGluZW5vLFxuICAgICAgICAgIGNvbG5vOiBjb2xubyxcbiAgICAgICAgICBlcnJvcjogZXJyb3IsXG4gICAgICAgICAgdHlwZTogdGhpcy5pc0ludGVyYWN0aW9uRXJyb3IgPyAnaW50ZXJhY3Rpb24nIDogJ2phdmFzY3JpcHQnLFxuICAgICAgICAgIHRpbWVzdGFtcDogbmV3IERhdGUoKS50b0lTT1N0cmluZygpXG4gICAgICAgIH0pO1xuICAgICAgICByZXR1cm4gdHJ1ZTsgLy8gUHJldmVudCBkZWZhdWx0IGJyb3dzZXIgZXJyb3IgaGFuZGxpbmdcbiAgICAgIH07XG4gICAgfVxuXG4gICAgLy8gQWxzbyB1c2UgYWRkRXZlbnRMaXN0ZW5lciBmb3IgYWRkaXRpb25hbCBlcnJvciBjYXB0dXJlIGNhcGFiaWxpdGllc1xuICAgIHdpbmRvdy5hZGRFdmVudExpc3RlbmVyKCdlcnJvcicsIChldmVudCkgPT4ge1xuICAgICAgLy8gT25seSBoYW5kbGUgaWYgbm90IGFscmVhZHkgaGFuZGxlZCBieSB3aW5kb3cub25lcnJvclxuICAgICAgaWYgKHdpbmRvdy5vbmVycm9yICYmIHR5cGVvZiB3aW5kb3cub25lcnJvciA9PT0gJ2Z1bmN0aW9uJykge1xuICAgICAgICAvLyB3aW5kb3cub25lcnJvciBhbHJlYWR5IGhhbmRsZWQgdGhpcywgYnV0IHdlIGNhbiBhZGQgYWRkaXRpb25hbCBwcm9jZXNzaW5nIGlmIG5lZWRlZFxuICAgICAgICByZXR1cm47XG4gICAgICB9XG5cbiAgICAgIHRoaXMuaGFuZGxlRXJyb3Ioe1xuICAgICAgICBtZXNzYWdlOiBldmVudC5tZXNzYWdlLFxuICAgICAgICBmaWxlbmFtZTogZXZlbnQuZmlsZW5hbWUsXG4gICAgICAgIGxpbmVubzogZXZlbnQubGluZW5vLFxuICAgICAgICBjb2xubzogZXZlbnQuY29sbm8sXG4gICAgICAgIGVycm9yOiBldmVudC5lcnJvcixcbiAgICAgICAgdHlwZTogdGhpcy5pc0ludGVyYWN0aW9uRXJyb3IgPyAnaW50ZXJhY3Rpb24nIDogJ2phdmFzY3JpcHQnLFxuICAgICAgICB0aW1lc3RhbXA6IG5ldyBEYXRlKCkudG9JU09TdHJpbmcoKVxuICAgICAgfSk7XG4gICAgfSk7XG5cbiAgICAvLyBDYXB0dXJlIHVuaGFuZGxlZCBwcm9taXNlIHJlamVjdGlvbnNcbiAgICB3aW5kb3cuYWRkRXZlbnRMaXN0ZW5lcigndW5oYW5kbGVkcmVqZWN0aW9uJywgKGV2ZW50KSA9PiB7XG4gICAgICB0aGlzLmhhbmRsZUVycm9yKHtcbiAgICAgICAgbWVzc2FnZTogZXZlbnQucmVhc29uPy5tZXNzYWdlIHx8ICdVbmhhbmRsZWQgUHJvbWlzZSBSZWplY3Rpb24nLFxuICAgICAgICBlcnJvcjogZXZlbnQucmVhc29uLFxuICAgICAgICB0eXBlOiAncHJvbWlzZScsXG4gICAgICAgIHRpbWVzdGFtcDogbmV3IERhdGUoKS50b0lTT1N0cmluZygpXG4gICAgICB9KTtcbiAgICB9KTtcblxuICAgIC8vIEludGVyY2VwdCBmZXRjaCBlcnJvcnNcbiAgICB0aGlzLmludGVyY2VwdEZldGNoKCk7XG4gICAgLy8gSW50ZXJjZXB0IFhIUiBlcnJvcnNcbiAgICB0aGlzLmludGVyY2VwdFhIUigpO1xuICB9XG5cbiAgc2V0dXBJbnRlcmFjdGlvblRyYWNraW5nKCkge1xuICAgIC8vIFRyYWNrIHVzZXIgaW50ZXJhY3Rpb25zIHRvIGlkZW50aWZ5IGludGVyYWN0aW9uLXRyaWdnZXJlZCBlcnJvcnNcbiAgICBbJ2NsaWNrJywgJ3N1Ym1pdCcsICdjaGFuZ2UnLCAna2V5ZG93biddLmZvckVhY2goZXZlbnRUeXBlID0+IHtcbiAgICAgIGRvY3VtZW50LmFkZEV2ZW50TGlzdGVuZXIoZXZlbnRUeXBlLCAoZXZlbnQpID0+IHtcbiAgICAgICAgdGhpcy5pc0ludGVyYWN0aW9uRXJyb3IgPSB0cnVlO1xuICAgICAgICB0aGlzLmxhc3RJbnRlcmFjdGlvblRpbWUgPSBEYXRlLm5vdygpO1xuXG4gICAgICAgIC8vIFJlY29yZCBsYXN0IHVzZXIgYWN0aW9uXG4gICAgICAgIHRoaXMucmVjb3JkVXNlckFjdGlvbihldmVudFR5cGUsIGV2ZW50KTtcblxuICAgICAgICBzZXRUaW1lb3V0KCgpID0+IHtcbiAgICAgICAgICB0aGlzLmlzSW50ZXJhY3Rpb25FcnJvciA9IGZhbHNlO1xuICAgICAgICB9LCAyMDAwKTsgLy8gMiBzZWNvbmQgd2luZG93IGZvciBpbnRlcmFjdGlvbiBlcnJvcnNcbiAgICAgIH0pO1xuICAgIH0pO1xuXG4gICAgLy8gQ2hlY2sgZm9yIHBsYWNlaG9sZGVyIGxpbmtzIG9uIGNsaWNrXG4gICAgZG9jdW1lbnQuYWRkRXZlbnRMaXN0ZW5lcignY2xpY2snLCAoZXZlbnQpID0+IHtcbiAgICAgIGNvbnN0IHRhcmdldCA9IGV2ZW50LnRhcmdldCBhcyBIVE1MRWxlbWVudDtcbiAgICAgIGlmICghdGFyZ2V0KSByZXR1cm47XG5cbiAgICAgIGNvbnN0IGxpbmsgPSB0YXJnZXQuY2xvc2VzdCgnYScpO1xuICAgICAgaWYgKCFsaW5rKSByZXR1cm47XG5cbiAgICAgIGNvbnN0IGhyZWYgPSBsaW5rLmdldEF0dHJpYnV0ZSgnaHJlZicpO1xuXG4gICAgICAvLyBDaGVjayBmb3IgcGxhY2Vob2xkZXIvaW52YWxpZCBocmVmIHZhbHVlc1xuICAgICAgaWYgKCFocmVmIHx8IGhyZWYgPT09ICcjJyB8fCBocmVmID09PSAnIyEnIHx8IGhyZWYuc3RhcnRzV2l0aCgnamF2YXNjcmlwdDonKSkge1xuICAgICAgICAvLyBDaGVjayBpZiB0aGlzIGxpbmsgaGFzIGEgZGF0YS1hY3Rpb24gKFN0aW11bHVzIGFjdGlvbiksIGlmIHNvLCBpdCdzIE9LXG4gICAgICAgIGlmIChsaW5rLmhhc0F0dHJpYnV0ZSgnZGF0YS1hY3Rpb24nKSkge1xuICAgICAgICAgIHJldHVybjtcbiAgICAgICAgfVxuXG4gICAgICAgIC8vIFJlcG9ydCBwbGFjZWhvbGRlciBsaW5rIGVycm9yXG4gICAgICAgIHRoaXMuaGFuZGxlRXJyb3Ioe1xuICAgICAgICAgIG1lc3NhZ2U6IGBDbGlja2VkIHBsYWNlaG9sZGVyIGxpbmsgd2l0aCBocmVmPVwiJHtocmVmIHx8ICcoZW1wdHkpJ31cIiAtIFVzZSByZWFsIFJhaWxzIHJvdXRlcyBpbnN0ZWFkYCxcbiAgICAgICAgICB0eXBlOiAnaW50ZXJhY3Rpb24nLFxuICAgICAgICAgIHRpbWVzdGFtcDogbmV3IERhdGUoKS50b0lTT1N0cmluZygpLFxuICAgICAgICAgIGZpbGVuYW1lOiB3aW5kb3cubG9jYXRpb24ucGF0aG5hbWUsXG4gICAgICAgICAgZXJyb3I6IG5ldyBFcnJvcihgUGxhY2Vob2xkZXIgbGluayBkZXRlY3RlZDogJHtsaW5rLm91dGVySFRNTC5zdWJzdHJpbmcoMCwgMTAwKX1gKVxuICAgICAgICB9KTtcbiAgICAgIH1cbiAgICB9LCB0cnVlKTsgLy8gVXNlIGNhcHR1cmUgcGhhc2UgdG8gY2F0Y2ggYmVmb3JlIG90aGVyIGhhbmRsZXJzXG5cbiAgICAvLyBDaGVjayBmb3IgcGxhY2Vob2xkZXIgZm9ybSBhY3Rpb25zIG9uIHN1Ym1pdFxuICAgIGRvY3VtZW50LmFkZEV2ZW50TGlzdGVuZXIoJ3N1Ym1pdCcsIChldmVudCkgPT4ge1xuICAgICAgY29uc3QgZm9ybSA9IGV2ZW50LnRhcmdldCBhcyBIVE1MRm9ybUVsZW1lbnQ7XG4gICAgICBpZiAoIWZvcm0pIHJldHVybjtcblxuICAgICAgY29uc3QgYWN0aW9uID0gZm9ybS5nZXRBdHRyaWJ1dGUoJ2FjdGlvbicpO1xuXG4gICAgICAvLyBDaGVjayBmb3IgcGxhY2Vob2xkZXIvaW52YWxpZCBhY3Rpb24gdmFsdWVzXG4gICAgICBpZiAoIWFjdGlvbiB8fCBhY3Rpb24gPT09ICcjJyB8fCBhY3Rpb24gPT09ICcjIScgfHwgYWN0aW9uLnN0YXJ0c1dpdGgoJ2phdmFzY3JpcHQ6JykpIHtcbiAgICAgICAgLy8gQ2hlY2sgaWYgdGhpcyBmb3JtIGhhcyBhIGRhdGEtYWN0aW9uIChTdGltdWx1cy9UdXJibyBhY3Rpb24pLCBpZiBzbywgaXQncyBPS1xuICAgICAgICBpZiAoZm9ybS5oYXNBdHRyaWJ1dGUoJ2RhdGEtYWN0aW9uJykgfHwgZm9ybS5oYXNBdHRyaWJ1dGUoJ2RhdGEtdHVyYm8tc3RyZWFtJykpIHtcbiAgICAgICAgICByZXR1cm47XG4gICAgICAgIH1cblxuICAgICAgICAvLyBSZXBvcnQgcGxhY2Vob2xkZXIgZm9ybSBhY3Rpb24gZXJyb3JcbiAgICAgICAgdGhpcy5oYW5kbGVFcnJvcih7XG4gICAgICAgICAgbWVzc2FnZTogYFN1Ym1pdHRlZCBmb3JtIHdpdGggcGxhY2Vob2xkZXIgYWN0aW9uPVwiJHthY3Rpb24gfHwgJyhlbXB0eSknfVwiIC0gVXNlIHJlYWwgUmFpbHMgcm91dGVzIGluc3RlYWRgLFxuICAgICAgICAgIHR5cGU6ICdpbnRlcmFjdGlvbicsXG4gICAgICAgICAgdGltZXN0YW1wOiBuZXcgRGF0ZSgpLnRvSVNPU3RyaW5nKCksXG4gICAgICAgICAgZmlsZW5hbWU6IHdpbmRvdy5sb2NhdGlvbi5wYXRobmFtZSxcbiAgICAgICAgICBlcnJvcjogbmV3IEVycm9yKGBQbGFjZWhvbGRlciBmb3JtIGFjdGlvbiBkZXRlY3RlZDogJHtmb3JtLm91dGVySFRNTC5zdWJzdHJpbmcoMCwgMTAwKX1gKVxuICAgICAgICB9KTtcbiAgICAgIH1cbiAgICB9LCB0cnVlKTsgLy8gVXNlIGNhcHR1cmUgcGhhc2UgdG8gY2F0Y2ggYmVmb3JlIG90aGVyIGhhbmRsZXJzXG4gIH1cblxuICBpbnRlcmNlcHRGZXRjaCgpIHtcbiAgICBjb25zdCBvcmlnaW5hbEZldGNoID0gd2luZG93LmZldGNoO1xuICAgIHdpbmRvdy5mZXRjaCA9IGFzeW5jICguLi5hcmdzKSA9PiB7XG4gICAgICBjb25zdCByZXNwb25zZSA9IGF3YWl0IG9yaWdpbmFsRmV0Y2goLi4uYXJncyk7XG5cbiAgICAgIGlmIChyZXNwb25zZS5zdGF0dXMgPj0gNTAwKSB7XG4gICAgICAgIGNvbnN0IGNvbnRlbnRUeXBlID0gcmVzcG9uc2UuaGVhZGVycy5nZXQoJ2NvbnRlbnQtdHlwZScpO1xuICAgICAgICBjb25zdCByZXF1ZXN0T3B0aW9ucyA9IGFyZ3NbMV0gfHwge307XG4gICAgICAgIGNvbnN0IG1ldGhvZCA9IChyZXF1ZXN0T3B0aW9ucy5tZXRob2QgfHwgJ0dFVCcpLnRvVXBwZXJDYXNlKCk7XG5cbiAgICAgICAgLy8gNTAwIGVycm9yczogcmVwb3J0IGJvdGggSFRNTCBhbmQgSlNPTlxuICAgICAgICAvLyA1MDErIGVycm9yczogb25seSByZXBvcnQgSlNPTlxuICAgICAgICBjb25zdCBzaG91bGRSZXBvcnQgPSByZXNwb25zZS5zdGF0dXMgPT09IDUwMCB8fFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIChjb250ZW50VHlwZSAmJiBjb250ZW50VHlwZS5pbmNsdWRlcygnYXBwbGljYXRpb24vanNvbicpKTtcblxuICAgICAgICBpZiAoc2hvdWxkUmVwb3J0KSB7XG4gICAgICAgICAgbGV0IGpzb25FcnJvciA9IG51bGw7XG5cbiAgICAgICAgICB0cnkge1xuICAgICAgICAgICAgY29uc3QgcmVzcG9uc2VDbG9uZSA9IHJlc3BvbnNlLmNsb25lKCk7XG4gICAgICAgICAgICBqc29uRXJyb3IgPSBhd2FpdCByZXNwb25zZUNsb25lLmpzb24oKTtcbiAgICAgICAgICB9IGNhdGNoIChib2R5RXJyb3IpIHtcbiAgICAgICAgICAgIC8vIElmIG5vdCBKU09OLCBpZ25vcmUgdGhlIGVycm9yIChpdCdzIGxpa2VseSBIVE1MKVxuICAgICAgICAgICAganNvbkVycm9yID0gbnVsbDtcbiAgICAgICAgICB9XG5cbiAgICAgICAgICAvLyBDcmVhdGUgZGV0YWlsZWQgZXJyb3IgbWVzc2FnZVxuICAgICAgICAgIGxldCBkZXRhaWxlZE1lc3NhZ2UgPSBgJHttZXRob2R9ICR7YXJnc1swXX0gLSBIVFRQICR7cmVzcG9uc2Uuc3RhdHVzfWA7XG4gICAgICAgICAgaWYgKGpzb25FcnJvcikge1xuICAgICAgICAgICAgY29uc3QgZXJyb3JNc2cgPSBqc29uRXJyb3IuZXJyb3IgfHwganNvbkVycm9yLm1lc3NhZ2UgfHwganNvbkVycm9yLmVycm9ycyB8fCAnVW5rbm93biBlcnJvcic7XG4gICAgICAgICAgICBkZXRhaWxlZE1lc3NhZ2UgKz0gYCAtICR7ZXJyb3JNc2d9YDtcbiAgICAgICAgICB9XG5cbiAgICAgICAgICB0aGlzLmhhbmRsZUVycm9yKHtcbiAgICAgICAgICAgIG1lc3NhZ2U6IGRldGFpbGVkTWVzc2FnZSxcbiAgICAgICAgICAgIHVybDogYXJnc1swXS50b1N0cmluZygpLFxuICAgICAgICAgICAgbWV0aG9kOiBtZXRob2QsXG4gICAgICAgICAgICB0eXBlOiAnaHR0cCcsXG4gICAgICAgICAgICBzdGF0dXM6IHJlc3BvbnNlLnN0YXR1cyxcbiAgICAgICAgICAgIGpzb25FcnJvcjoganNvbkVycm9yLFxuICAgICAgICAgICAgdGltZXN0YW1wOiBuZXcgRGF0ZSgpLnRvSVNPU3RyaW5nKClcbiAgICAgICAgICB9KTtcbiAgICAgICAgfVxuICAgICAgfVxuXG4gICAgICByZXR1cm4gcmVzcG9uc2U7XG4gICAgfTtcbiAgfVxuXG4gIGludGVyY2VwdFhIUigpIHtcbiAgICBjb25zdCBvcmlnaW5hbFhIUk9wZW4gPSBYTUxIdHRwUmVxdWVzdC5wcm90b3R5cGUub3BlbjtcbiAgICBjb25zdCBvcmlnaW5hbFhIUlNlbmQgPSBYTUxIdHRwUmVxdWVzdC5wcm90b3R5cGUuc2VuZDtcblxuICAgIFhNTEh0dHBSZXF1ZXN0LnByb3RvdHlwZS5vcGVuID0gZnVuY3Rpb24obWV0aG9kOiBzdHJpbmcsIHVybDogc3RyaW5nIHwgVVJMLCBhc3luYz86IGJvb2xlYW4sIHVzZXI/OiBzdHJpbmcgfCBudWxsLCBwYXNzd29yZD86IHN0cmluZyB8IG51bGwpIHtcbiAgICAgICh0aGlzIGFzIGFueSkuX2Vycm9ySGFuZGxlcl9tZXRob2QgPSBtZXRob2QudG9VcHBlckNhc2UoKTtcbiAgICAgICh0aGlzIGFzIGFueSkuX2Vycm9ySGFuZGxlcl91cmwgPSB1cmwudG9TdHJpbmcoKTtcbiAgICAgIHJldHVybiBvcmlnaW5hbFhIUk9wZW4uY2FsbCh0aGlzLCBtZXRob2QsIHVybCwgYXN5bmMgPz8gdHJ1ZSwgdXNlciwgcGFzc3dvcmQpO1xuICAgIH07XG5cbiAgICBYTUxIdHRwUmVxdWVzdC5wcm90b3R5cGUuc2VuZCA9IGZ1bmN0aW9uKGJvZHk/OiBhbnkpIHtcbiAgICAgIGNvbnN0IHhociA9IHRoaXMgYXMgYW55O1xuICAgICAgY29uc3QgbWV0aG9kID0geGhyLl9lcnJvckhhbmRsZXJfbWV0aG9kIHx8ICdHRVQnO1xuICAgICAgY29uc3QgdXJsID0geGhyLl9lcnJvckhhbmRsZXJfdXJsIHx8ICd1bmtub3duJztcblxuICAgICAgLy8gU2tpcCBuZXR3b3JrIGVycm9yIGFuZCB0aW1lb3V0IGxpc3RlbmVycyAobm90IGFjdGlvbmFibGUgZnJvbnRlbmQgZXJyb3JzKVxuXG4gICAgICB4aHIuYWRkRXZlbnRMaXN0ZW5lcignbG9hZGVuZCcsICgpID0+IHtcbiAgICAgICAgaWYgKHhoci5zdGF0dXMgPj0gNTAwKSB7XG4gICAgICAgICAgY29uc3QgY29udGVudFR5cGUgPSB4aHIuZ2V0UmVzcG9uc2VIZWFkZXIoJ2NvbnRlbnQtdHlwZScpO1xuXG4gICAgICAgICAgLy8gNTAwIGVycm9yczogcmVwb3J0IGJvdGggSFRNTCBhbmQgSlNPTlxuICAgICAgICAgIC8vIDUwMSsgZXJyb3JzOiBvbmx5IHJlcG9ydCBKU09OXG4gICAgICAgICAgY29uc3Qgc2hvdWxkUmVwb3J0ID0geGhyLnN0YXR1cyA9PT0gNTAwIHx8XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAoY29udGVudFR5cGUgJiYgY29udGVudFR5cGUuaW5jbHVkZXMoJ2FwcGxpY2F0aW9uL2pzb24nKSk7XG5cbiAgICAgICAgICBpZiAoc2hvdWxkUmVwb3J0KSB7XG4gICAgICAgICAgICBsZXQganNvbkVycm9yID0gbnVsbDtcblxuICAgICAgICAgICAgdHJ5IHtcbiAgICAgICAgICAgICAganNvbkVycm9yID0gSlNPTi5wYXJzZSh4aHIucmVzcG9uc2VUZXh0KTtcbiAgICAgICAgICAgIH0gY2F0Y2ggKHBhcnNlRXJyb3IpIHtcbiAgICAgICAgICAgICAgLy8gSWYgbm90IEpTT04sIGlnbm9yZSB0aGUgZXJyb3IgKGl0J3MgbGlrZWx5IEhUTUwpXG4gICAgICAgICAgICAgIGpzb25FcnJvciA9IG51bGw7XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIC8vIENyZWF0ZSBkZXRhaWxlZCBlcnJvciBtZXNzYWdlXG4gICAgICAgICAgICBsZXQgZGV0YWlsZWRNZXNzYWdlID0gYCR7bWV0aG9kfSAke3VybH0gLSBIVFRQICR7eGhyLnN0YXR1c31gO1xuICAgICAgICAgICAgaWYgKGpzb25FcnJvcikge1xuICAgICAgICAgICAgICBjb25zdCBlcnJvck1zZyA9IGpzb25FcnJvci5lcnJvciB8fCBqc29uRXJyb3IubWVzc2FnZSB8fCBqc29uRXJyb3IuZXJyb3JzIHx8ICdVbmtub3duIGVycm9yJztcbiAgICAgICAgICAgICAgZGV0YWlsZWRNZXNzYWdlICs9IGAgLSAke2Vycm9yTXNnfWA7XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIHdpbmRvdy5lcnJvckhhbmRsZXI/LmhhbmRsZUVycm9yKHtcbiAgICAgICAgICAgICAgbWVzc2FnZTogZGV0YWlsZWRNZXNzYWdlLFxuICAgICAgICAgICAgICB1cmw6IHVybCxcbiAgICAgICAgICAgICAgbWV0aG9kOiBtZXRob2QsXG4gICAgICAgICAgICAgIHR5cGU6ICdodHRwJyxcbiAgICAgICAgICAgICAgc3RhdHVzOiB4aHIuc3RhdHVzLFxuICAgICAgICAgICAgICBqc29uRXJyb3I6IGpzb25FcnJvcixcbiAgICAgICAgICAgICAgdGltZXN0YW1wOiBuZXcgRGF0ZSgpLnRvSVNPU3RyaW5nKClcbiAgICAgICAgICAgIH0pO1xuICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgfSk7XG5cbiAgICAgIHJldHVybiBvcmlnaW5hbFhIUlNlbmQuY2FsbCh0aGlzLCBib2R5KTtcbiAgICB9O1xuICB9XG5cbiAgaGFuZGxlRXJyb3IoZXJyb3JJbmZvOiBFcnJvckluZm8pOiB2b2lkIHtcbiAgICAvLyBGaWx0ZXIgb3V0IGJyb3dzZXItc3BlY2lmaWMgZXJyb3JzIHdlIGNhbid0IGNvbnRyb2xcbiAgICBpZiAodGhpcy5zaG91bGRJZ25vcmVFcnJvcihlcnJvckluZm8pKSB7XG4gICAgICByZXR1cm47XG4gICAgfVxuXG4gICAgLy8gRW5yaWNoIGVycm9yIHdpdGggc291cmNlIG1hcCBhc3luY2hyb25vdXNseVxuICAgIHRoaXMuZW5yaWNoRXJyb3JXaXRoU291cmNlTWFwKGVycm9ySW5mbykudGhlbihlbnJpY2hlZEVycm9yID0+IHtcbiAgICAgIHRoaXMucHJvY2Vzc0Vycm9yKGVucmljaGVkRXJyb3IpO1xuICAgIH0pLmNhdGNoKGVyciA9PiB7XG4gICAgICB0aGlzLm9yaWdpbmFsQ29uc29sZUVycm9yKCdGYWlsZWQgdG8gZW5yaWNoIGVycm9yIHdpdGggc291cmNlIG1hcCcsIGVycik7XG4gICAgICAvLyBGYWxsIGJhY2sgdG8gcHJvY2Vzc2luZyBvcmlnaW5hbCBlcnJvclxuICAgICAgdGhpcy5wcm9jZXNzRXJyb3IoZXJyb3JJbmZvKTtcbiAgICB9KTtcbiAgfVxuXG4gIHByaXZhdGUgcHJvY2Vzc0Vycm9yKGVycm9ySW5mbzogRXJyb3JJbmZvKTogdm9pZCB7XG4gICAgLy8gQ3JlYXRlIGEgZGVib3VuY2Uga2V5IGZvciBzaW1pbGFyIGVycm9yc1xuICAgIGNvbnN0IGRlYm91bmNlS2V5ID0gYCR7ZXJyb3JJbmZvLnR5cGV9XyR7ZXJyb3JJbmZvLm1lc3NhZ2V9XyR7ZXJyb3JJbmZvLmZpbGVuYW1lfV8ke2Vycm9ySW5mby5saW5lbm99YDtcblxuICAgIC8vIENoZWNrIGlmIHRoaXMgZXJyb3Igd2FzIHJlY2VudGx5IHByb2Nlc3NlZCAoZGVib3VuY2luZylcbiAgICBpZiAodGhpcy5yZWNlbnRFcnJvcnNEZWJvdW5jZS5oYXMoZGVib3VuY2VLZXkpKSB7XG4gICAgICBjb25zdCBsYXN0VGltZSA9IHRoaXMucmVjZW50RXJyb3JzRGVib3VuY2UuZ2V0KGRlYm91bmNlS2V5KTtcbiAgICAgIGlmIChsYXN0VGltZSAmJiBEYXRlLm5vdygpIC0gbGFzdFRpbWUgPCB0aGlzLmRlYm91bmNlVGltZSkge1xuICAgICAgICAvLyBVcGRhdGUgZXhpc3RpbmcgZXJyb3IgY291bnQgaW5zdGVhZCBvZiBjcmVhdGluZyBuZXcgb25lXG4gICAgICAgIGNvbnN0IGV4aXN0aW5nRXJyb3IgPSB0aGlzLmZpbmREdXBsaWNhdGVFcnJvcihlcnJvckluZm8pO1xuICAgICAgICBpZiAoZXhpc3RpbmdFcnJvcikge1xuICAgICAgICAgIGV4aXN0aW5nRXJyb3IuY291bnQrKztcbiAgICAgICAgICBleGlzdGluZ0Vycm9yLmxhc3RPY2N1cnJlZCA9IGVycm9ySW5mby50aW1lc3RhbXA7XG4gICAgICAgICAgdGhpcy51cGRhdGVTdGF0dXNCYXIoKTtcbiAgICAgICAgICB0aGlzLnVwZGF0ZUVycm9yTGlzdCgpO1xuICAgICAgICB9XG4gICAgICAgIHJldHVybjtcbiAgICAgIH1cbiAgICB9XG5cbiAgICAvLyBTZXQgZGVib3VuY2UgdGltZXN0YW1wXG4gICAgdGhpcy5yZWNlbnRFcnJvcnNEZWJvdW5jZS5zZXQoZGVib3VuY2VLZXksIERhdGUubm93KCkpO1xuXG4gICAgLy8gQ2hlY2sgZm9yIGR1cGxpY2F0ZSBlcnJvcnNcbiAgICBjb25zdCBpc0R1cGxpY2F0ZSA9IHRoaXMuZmluZER1cGxpY2F0ZUVycm9yKGVycm9ySW5mbyk7XG4gICAgaWYgKGlzRHVwbGljYXRlKSB7XG4gICAgICBpc0R1cGxpY2F0ZS5jb3VudCsrO1xuICAgICAgaXNEdXBsaWNhdGUubGFzdE9jY3VycmVkID0gZXJyb3JJbmZvLnRpbWVzdGFtcDtcbiAgICB9IGVsc2Uge1xuICAgICAgLy8gQWRkIG5ldyBlcnJvclxuICAgICAgY29uc3QgZXJyb3IgPSB7XG4gICAgICAgIGlkOiB0aGlzLmdlbmVyYXRlRXJyb3JJZCgpLFxuICAgICAgICAuLi5lcnJvckluZm8sXG4gICAgICAgIGNvdW50OiAxLFxuICAgICAgICBsYXN0T2NjdXJyZWQ6IGVycm9ySW5mby50aW1lc3RhbXAsXG4gICAgICB9O1xuXG4gICAgICB0aGlzLmVycm9ycy51bnNoaWZ0KGVycm9yKTtcblxuICAgICAgLy8gS2VlcCBvbmx5IHJlY2VudCBlcnJvcnNcbiAgICAgIGlmICh0aGlzLmVycm9ycy5sZW5ndGggPiB0aGlzLm1heEVycm9ycykge1xuICAgICAgICB0aGlzLmVycm9ycyA9IHRoaXMuZXJyb3JzLnNsaWNlKDAsIHRoaXMubWF4RXJyb3JzKTtcbiAgICAgIH1cbiAgICB9XG5cbiAgICAvLyBVcGRhdGUgY291bnRzXG4gICAgaWYgKGVycm9ySW5mby50eXBlIGluIHRoaXMuZXJyb3JDb3VudHMpIHtcbiAgICAgIHRoaXMuZXJyb3JDb3VudHNbZXJyb3JJbmZvLnR5cGUgYXMga2V5b2YgRXJyb3JDb3VudHNdKys7XG4gICAgfVxuXG4gICAgLy8gVXBkYXRlIFVJIChpZiByZWFkeSkgb3IgbWFyayBmb3IgbGF0ZXIgdXBkYXRlXG4gICAgaWYgKHRoaXMudWlSZWFkeSkge1xuICAgICAgdGhpcy51cGRhdGVTdGF0dXNCYXIoKTtcbiAgICAgIHRoaXMudXBkYXRlRXJyb3JMaXN0KCk7XG4gICAgICB0aGlzLnNob3dTdGF0dXNCYXIoKTtcbiAgICAgIHRoaXMuZmxhc2hOZXdFcnJvcigpO1xuICAgIH0gZWxzZSB7XG4gICAgICB0aGlzLnBlbmRpbmdVSVVwZGF0ZXMgPSB0cnVlO1xuICAgIH1cblxuICAgIC8vIENsZWFuIHVwIG9sZCBkZWJvdW5jZSBlbnRyaWVzXG4gICAgdGhpcy5jbGVhbnVwRGVib3VuY2VNYXAoKTtcbiAgfVxuXG4gIHNob3VsZElnbm9yZUVycm9yKGVycm9ySW5mbzogRXJyb3JJbmZvKTogYm9vbGVhbiB7XG4gICAgY29uc3QgaWdub3JlZFBhdHRlcm5zID0gW1xuICAgICAgLy8gQnJvd3NlciBleHRlbnNpb24gZXJyb3JzXG4gICAgICAvY2hyb21lLWV4dGVuc2lvbjovLFxuICAgICAgL21vei1leHRlbnNpb246LyxcbiAgICAgIC9zYWZhcmktZXh0ZW5zaW9uOi8sXG5cbiAgICAgIC8vIENvbW1vbiBicm93c2VyIGVycm9ycyB3ZSBjYW4ndCBjb250cm9sXG4gICAgICAvU2NyaXB0IGVycm9yLyxcbiAgICAgIC9Ob24tRXJyb3IgcHJvbWlzZSByZWplY3Rpb24gY2FwdHVyZWQvLFxuICAgICAgL1Jlc2l6ZU9ic2VydmVyIGxvb3AvLFxuICAgICAgL3Bhc3NpdmUgZXZlbnQgbGlzdGVuZXIvLFxuXG4gICAgICAvLyBUdXJibyBuYXZpZ2F0aW9uIGFib3J0ZWQgcmVxdWVzdHMgKG5vcm1hbCBiZWhhdmlvcilcbiAgICAgIC91c2VyIGFib3J0ZWQvaSxcbiAgICAgIC9BYm9ydEVycm9yLyxcbiAgICAgIC9yZXF1ZXN0LiphYm9ydGVkL2ksXG5cbiAgICAgIC8vIFRoaXJkLXBhcnR5IHNjcmlwdCBlcnJvcnNcbiAgICAgIC9nb29nbGUtYW5hbHl0aWNzLyxcbiAgICAgIC9nb29nbGV0YWdtYW5hZ2VyLyxcbiAgICAgIC9mYWNlYm9va1xcLm5ldC8sXG4gICAgICAvdHdpdHRlclxcLmNvbS8sXG5cbiAgICAgIC8vIFByZXZpZXcvRGVidWcgU0RLc1xuICAgICAgL2NsYWNreS1wcmV2aWV3LXNkay8sXG5cbiAgICAgIC8vIGlPUyBTYWZhcmkgc3BlY2lmaWNcbiAgICAgIC9XZWJLaXRCbG9iUmVzb3VyY2UvLFxuICAgIF07XG5cbiAgICBjb25zdCBtZXNzYWdlID0gZXJyb3JJbmZvLm1lc3NhZ2UgfHwgJyc7XG4gICAgY29uc3QgZmlsZW5hbWUgPSBlcnJvckluZm8uZmlsZW5hbWUgfHwgJyc7XG5cbiAgICByZXR1cm4gaWdub3JlZFBhdHRlcm5zLnNvbWUocGF0dGVybiA9PlxuICAgICAgcGF0dGVybi50ZXN0KG1lc3NhZ2UpIHx8IHBhdHRlcm4udGVzdChmaWxlbmFtZSlcbiAgICApO1xuICB9XG5cbiAgZmluZER1cGxpY2F0ZUVycm9yKGVycm9ySW5mbzogRXJyb3JJbmZvKTogU3RvcmVkRXJyb3IgfCB1bmRlZmluZWQge1xuICAgIHJldHVybiB0aGlzLmVycm9ycy5maW5kKGVycm9yID0+IHtcbiAgICAgIC8vIFVzZSBwYXJ0aWFsIG1lc3NhZ2UgbWF0Y2hpbmcgdG8gaGFuZGxlIHZhcmlhdGlvbnNcbiAgICAgIGNvbnN0IGV4aXN0aW5nTXNnID0gZXJyb3IubWVzc2FnZS5yZXBsYWNlKC9eXFxbY29uc29sZVxcLmVycm9yXFxdXFxzKi8sICcnKTtcbiAgICAgIGNvbnN0IG5ld01zZyA9IGVycm9ySW5mby5tZXNzYWdlLnJlcGxhY2UoL15cXFtjb25zb2xlXFwuZXJyb3JcXF1cXHMqLywgJycpO1xuXG4gICAgICAvLyBDb25zaWRlciBpdCBkdXBsaWNhdGUgaWYgb25lIG1lc3NhZ2UgY29udGFpbnMgdGhlIG90aGVyXG4gICAgICBjb25zdCBtZXNzYWdlc01hdGNoID0gZXhpc3RpbmdNc2cuaW5jbHVkZXMobmV3TXNnKSB8fCBuZXdNc2cuaW5jbHVkZXMoZXhpc3RpbmdNc2cpO1xuICAgICAgaWYgKCFtZXNzYWdlc01hdGNoKSByZXR1cm4gZmFsc2U7XG5cbiAgICAgIC8vIFR5cGUgbWF0Y2hpbmc6IGphdmFzY3JpcHQgYW5kIGludGVyYWN0aW9uIGFyZSBjb25zaWRlcmVkIHNpbWlsYXJcbiAgICAgIGNvbnN0IHR5cGVzTWF0Y2ggPSBlcnJvci50eXBlID09PSBlcnJvckluZm8udHlwZSB8fFxuICAgICAgICAgICAgICAgICAgICAgICAgKGVycm9yLnR5cGUgPT09ICdqYXZhc2NyaXB0JyAmJiBlcnJvckluZm8udHlwZSA9PT0gJ2ludGVyYWN0aW9uJykgfHxcbiAgICAgICAgICAgICAgICAgICAgICAgIChlcnJvci50eXBlID09PSAnaW50ZXJhY3Rpb24nICYmIGVycm9ySW5mby50eXBlID09PSAnamF2YXNjcmlwdCcpO1xuICAgICAgaWYgKCF0eXBlc01hdGNoKSByZXR1cm4gZmFsc2U7XG5cbiAgICAgIC8vIE9ubHkgY2hlY2sgZmlsZW5hbWUvbGluZW5vIGlmIGJvdGggZXJyb3JzIGhhdmUgdGhlbVxuICAgICAgLy8gSWYgb25lIGhhcyB0aGVtIGFuZCB0aGUgb3RoZXIgZG9lc24ndCwgc3RpbGwgY29uc2lkZXIgaXQgYSBtYXRjaCBiYXNlZCBvbiBtZXNzYWdlXG4gICAgICBjb25zdCBib3RoSGF2ZUxvY2F0aW9uID0gZXJyb3IuZmlsZW5hbWUgJiYgZXJyb3JJbmZvLmZpbGVuYW1lO1xuICAgICAgaWYgKGJvdGhIYXZlTG9jYXRpb24pIHtcbiAgICAgICAgLy8gSWYgYm90aCBoYXZlIGxvY2F0aW9uIGluZm8sIHRoZXkgc2hvdWxkIG1hdGNoXG4gICAgICAgIGlmIChlcnJvci5maWxlbmFtZSAhPT0gZXJyb3JJbmZvLmZpbGVuYW1lIHx8IGVycm9yLmxpbmVubyAhPT0gZXJyb3JJbmZvLmxpbmVubykge1xuICAgICAgICAgIHJldHVybiBmYWxzZTtcbiAgICAgICAgfVxuICAgICAgfVxuXG4gICAgICByZXR1cm4gdHJ1ZTtcbiAgICB9KTtcbiAgfVxuXG4gIGdlbmVyYXRlRXJyb3JJZCgpIHtcbiAgICByZXR1cm4gYGVycm9yXyR7ICBEYXRlLm5vdygpICB9XyR7ICBNYXRoLnJhbmRvbSgpLnRvU3RyaW5nKDM2KS5zdWJzdHIoMiwgOSl9YDtcbiAgfVxuXG4gIHVwZGF0ZVN0YXR1c0JhcigpIHtcbiAgICBjb25zdCBzdW1tYXJ5ID0gZG9jdW1lbnQuZ2V0RWxlbWVudEJ5SWQoJ2Vycm9yLXN1bW1hcnknKTtcbiAgICBjb25zdCBjb3B5QnV0dG9uID0gZG9jdW1lbnQuZ2V0RWxlbWVudEJ5SWQoJ2NvcHktYWxsLWVycm9ycycpO1xuICAgIGNvbnN0IHRpcHNFbGVtZW50ID0gZG9jdW1lbnQuZ2V0RWxlbWVudEJ5SWQoJ2Vycm9yLXRpcHMnKTtcbiAgICBpZiAoIXN1bW1hcnkpIHJldHVybjsgLy8gVUkgbm90IHJlYWR5IHlldFxuXG4gICAgY29uc3QgdG90YWxFcnJvcnMgPSB0aGlzLmVycm9ycy5yZWR1Y2UoKHN1bSwgZXJyb3IpID0+IHN1bSArIGVycm9yLmNvdW50LCAwKTtcblxuICAgIGlmICh0b3RhbEVycm9ycyA9PT0gMCkge1xuICAgICAgc3VtbWFyeS5pbm5lckhUTUwgPSAnPHNwYW4gY2xhc3M9XCJ0ZXh0LWdyZWVuLTQwMFwiPlx1MjcxMyBObyBFcnJvcnM8L3NwYW4+JztcbiAgICAgIGlmIChjb3B5QnV0dG9uKSBjb3B5QnV0dG9uLnN0eWxlLmRpc3BsYXkgPSAnbm9uZSc7XG4gICAgICBpZiAodGlwc0VsZW1lbnQpIHRpcHNFbGVtZW50LnN0eWxlLmRpc3BsYXkgPSAnbm9uZSc7XG4gICAgICByZXR1cm47XG4gICAgfVxuXG4gICAgLy8gVW5pZmllZCBlcnJvciBkaXNwbGF5IHdpdGhvdXQgdHlwZSBkaXN0aW5jdGlvblxuICAgIHN1bW1hcnkuaW5uZXJIVE1MID0gYDxzcGFuIGNsYXNzPVwidGV4dC1yZWQtNDAwXCI+XHVEODNEXHVERDM0IEZyb250ZW5kIGNvZGUgZXJyb3IgZGV0ZWN0ZWQgKCR7dG90YWxFcnJvcnN9KTwvc3Bhbj5gO1xuICAgIGlmIChjb3B5QnV0dG9uKSBjb3B5QnV0dG9uLnN0eWxlLmRpc3BsYXkgPSAnYmxvY2snO1xuICAgIGlmICh0aXBzRWxlbWVudCkgdGlwc0VsZW1lbnQuc3R5bGUuZGlzcGxheSA9ICdibG9jayc7XG4gIH1cblxuICB1cGRhdGVFcnJvckxpc3QoKSB7XG4gICAgaWYgKCF0aGlzLmVycm9yTGlzdCkgcmV0dXJuOyAvLyBVSSBub3QgcmVhZHkgeWV0XG5cbiAgICBjb25zdCBsaXN0SFRNTCA9IHRoaXMuZXJyb3JzLm1hcChlcnJvciA9PiB0aGlzLmNyZWF0ZUVycm9ySXRlbUhUTUwoZXJyb3IpKS5qb2luKCcnKTtcbiAgICB0aGlzLmVycm9yTGlzdC5pbm5lckhUTUwgPSBsaXN0SFRNTDtcblxuICAgIC8vIEF0dGFjaCBldmVudCBsaXN0ZW5lcnMgdG8gbmV3IGVycm9yIGl0ZW1zXG4gICAgdGhpcy5hdHRhY2hFcnJvckl0ZW1MaXN0ZW5lcnMoKTtcbiAgfVxuXG4gIGNyZWF0ZUVycm9ySXRlbUhUTUwoZXJyb3I6IFN0b3JlZEVycm9yKTogc3RyaW5nIHtcbiAgICBjb25zdCBpY29uID0gdGhpcy5nZXRFcnJvckljb24oZXJyb3IudHlwZSk7XG4gICAgY29uc3QgY291bnRUZXh0ID0gZXJyb3IuY291bnQgPiAxID8gYCAoJHtlcnJvci5jb3VudH14KWAgOiAnJztcbiAgICBjb25zdCB0aW1lU3RyID0gbmV3IERhdGUoZXJyb3IudGltZXN0YW1wKS50b0xvY2FsZVRpbWVTdHJpbmcoKTtcblxuICAgIHJldHVybiBgXG4gICAgICA8ZGl2IGNsYXNzPVwiZmxleCBpdGVtcy1zdGFydCBqdXN0aWZ5LWJldHdlZW4gYmctZ3JheS03MDAgcm91bmRlZCBwLTMgZXJyb3ItaXRlbVwiIGRhdGEtZXJyb3ItaWQ9XCIke2Vycm9yLmlkfVwiPlxuICAgICAgICA8ZGl2IGNsYXNzPVwiZmxleCBpdGVtcy1zdGFydCBzcGFjZS14LTMgZmxleC0xXCI+XG4gICAgICAgICAgPGRpdiBjbGFzcz1cInRleHQtbGdcIj4ke2ljb259PC9kaXY+XG4gICAgICAgICAgPGRpdiBjbGFzcz1cImZsZXgtMSBtaW4tdy0wXCI+XG4gICAgICAgICAgICA8ZGl2IGNsYXNzPVwiZmxleCBpdGVtcy1jZW50ZXIganVzdGlmeS1iZXR3ZWVuXCI+XG4gICAgICAgICAgICAgIDxzcGFuIGNsYXNzPVwiZm9udC1tZWRpdW0gdGV4dC1zbSB0ZXh0LXdoaXRlIHRydW5jYXRlIHByLTJcIj4ke3RoaXMuc2FuaXRpemVNZXNzYWdlKGVycm9yLm1lc3NhZ2UpfTwvc3Bhbj5cbiAgICAgICAgICAgICAgPHNwYW4gY2xhc3M9XCJ0ZXh0LXhzIHRleHQtZ3JheS00MDAgd2hpdGVzcGFjZS1ub3dyYXAgbXQtMVwiPiR7dGltZVN0cn0ke2NvdW50VGV4dH08L3NwYW4+XG4gICAgICAgICAgICA8L2Rpdj5cbiAgICAgICAgICAgIDxkaXYgY2xhc3M9XCJ0ZWNobmljYWwtZGV0YWlscyBtdC0yIHRleHQteHMgdGV4dC1ncmF5LTUwMFwiIHN0eWxlPVwiZGlzcGxheTogbm9uZTtcIj5cbiAgICAgICAgICAgICAgJHt0aGlzLmZvcm1hdFRlY2huaWNhbERldGFpbHMoZXJyb3IpfVxuICAgICAgICAgICAgPC9kaXY+XG4gICAgICAgICAgPC9kaXY+XG4gICAgICAgIDwvZGl2PlxuICAgICAgICA8ZGl2IGNsYXNzPVwiZmxleCBpdGVtcy1jZW50ZXIgc3BhY2UteC0xIG1sLTNcIj5cbiAgICAgICAgICA8YnV0dG9uIGNsYXNzPVwiY29weS1lcnJvciB0ZXh0LWJsdWUtNDAwIGhvdmVyOnRleHQtYmx1ZS0zMDAgcHgtMiBweS0xIHRleHQteHMgcm91bmRlZFwiIHRpdGxlPVwiQ29weSBlcnJvciBmb3IgY2hhdGJveFwiPlxuICAgICAgICAgICAgQ29weVxuICAgICAgICAgIDwvYnV0dG9uPlxuICAgICAgICAgIDxidXR0b24gY2xhc3M9XCJ0b2dnbGUtZGV0YWlscyB0ZXh0LWdyYXktNDAwIGhvdmVyOnRleHQtZ3JheS0zMDAgcHgtMiBweS0xIHRleHQteHMgcm91bmRlZFwiIHRpdGxlPVwiVG9nZ2xlIGRldGFpbHNcIj5cbiAgICAgICAgICAgIERldGFpbHNcbiAgICAgICAgICA8L2J1dHRvbj5cbiAgICAgICAgICA8YnV0dG9uIGNsYXNzPVwiY2xvc2UtZXJyb3IgdGV4dC1yZWQtNDAwIGhvdmVyOnRleHQtcmVkLTMwMCBweC0yIHB5LTEgdGV4dC14cyByb3VuZGVkXCIgdGl0bGU9XCJDbG9zZVwiPlxuICAgICAgICAgICAgXHUwMEQ3XG4gICAgICAgICAgPC9idXR0b24+XG4gICAgICAgIDwvZGl2PlxuICAgICAgPC9kaXY+XG4gICAgYDtcbiAgfVxuXG4gIGF0dGFjaEVycm9ySXRlbUxpc3RlbmVycygpIHtcbiAgICAvLyBDb3B5IGVycm9yIGJ1dHRvbnNcbiAgICBkb2N1bWVudC5xdWVyeVNlbGVjdG9yQWxsKCcuY29weS1lcnJvcicpLmZvckVhY2goYnV0dG9uID0+IHtcbiAgICAgIGJ1dHRvbi5hZGRFdmVudExpc3RlbmVyKCdjbGljaycsIChlKSA9PiB7XG4gICAgICAgIGNvbnN0IGVycm9ySWQgPSAoKGUudGFyZ2V0IGFzIEhUTUxFbGVtZW50KS5jbG9zZXN0KCcuZXJyb3ItaXRlbScpIGFzIEhUTUxFbGVtZW50KT8uZGF0YXNldC5lcnJvcklkO1xuICAgICAgICBpZiAoZXJyb3JJZCkgdGhpcy5jb3B5RXJyb3JUb0NsaXBib2FyZChlcnJvcklkKTtcbiAgICAgIH0pO1xuICAgIH0pO1xuXG4gICAgLy8gVG9nZ2xlIGRldGFpbHMgYnV0dG9uc1xuICAgIGRvY3VtZW50LnF1ZXJ5U2VsZWN0b3JBbGwoJy50b2dnbGUtZGV0YWlscycpLmZvckVhY2goYnV0dG9uID0+IHtcbiAgICAgIGJ1dHRvbi5hZGRFdmVudExpc3RlbmVyKCdjbGljaycsIChlKSA9PiB7XG4gICAgICAgIGNvbnN0IGVycm9ySXRlbSA9IChlLnRhcmdldCBhcyBIVE1MRWxlbWVudCkuY2xvc2VzdCgnLmVycm9yLWl0ZW0nKTtcbiAgICAgICAgY29uc3QgZGV0YWlscyA9IGVycm9ySXRlbT8ucXVlcnlTZWxlY3RvcignLnRlY2huaWNhbC1kZXRhaWxzJykgYXMgSFRNTEVsZW1lbnQ7XG4gICAgICAgIGNvbnN0IGlzVmlzaWJsZSA9IGRldGFpbHM/LnN0eWxlLmRpc3BsYXkgIT09ICdub25lJztcblxuICAgICAgICBpZiAoZGV0YWlscykgZGV0YWlscy5zdHlsZS5kaXNwbGF5ID0gaXNWaXNpYmxlID8gJ25vbmUnIDogJ2Jsb2NrJztcbiAgICAgICAgKGUudGFyZ2V0IGFzIEhUTUxFbGVtZW50KS50ZXh0Q29udGVudCA9IGlzVmlzaWJsZSA/ICdEZXRhaWxzJyA6ICdIaWRlJztcbiAgICAgIH0pO1xuICAgIH0pO1xuXG4gICAgLy8gQ2xvc2UgZXJyb3IgYnV0dG9uc1xuICAgIGRvY3VtZW50LnF1ZXJ5U2VsZWN0b3JBbGwoJy5jbG9zZS1lcnJvcicpLmZvckVhY2goYnV0dG9uID0+IHtcbiAgICAgIGJ1dHRvbi5hZGRFdmVudExpc3RlbmVyKCdjbGljaycsIChlKSA9PiB7XG4gICAgICAgIGNvbnN0IGVycm9ySWQgPSAoKGUudGFyZ2V0IGFzIEhUTUxFbGVtZW50KS5jbG9zZXN0KCcuZXJyb3ItaXRlbScpIGFzIEhUTUxFbGVtZW50KT8uZGF0YXNldC5lcnJvcklkO1xuICAgICAgICBpZiAoZXJyb3JJZCkgdGhpcy5yZW1vdmVFcnJvcihlcnJvcklkKTtcbiAgICAgIH0pO1xuICAgIH0pO1xuICB9XG5cbiAgZ2V0RXJyb3JJY29uKHR5cGU6IHN0cmluZyk6IHN0cmluZyB7XG4gICAgcmV0dXJuIEVSUk9SX1RZUEVfQ09ORklHU1t0eXBlXT8uaWNvbiB8fCAnXHUyNzRDJztcbiAgfVxuXG4gIC8vIFVuaWZpZWQgZXJyb3IgZGV0YWlsIGZvcm1hdHRpbmdcbiAgcHJpdmF0ZSBmb3JtYXRFcnJvckRldGFpbHMoZXJyb3I6IFN0b3JlZEVycm9yLCBmb3JtYXQ6ICdodG1sJyB8ICd0ZXh0Jyk6IHN0cmluZ1tdIHtcbiAgICBjb25zdCBjb25maWcgPSBFUlJPUl9UWVBFX0NPTkZJR1NbZXJyb3IudHlwZV07XG4gICAgaWYgKCFjb25maWcpIHtcbiAgICAgIC8vIEZhbGxiYWNrIGZvciB1bmtub3duIGVycm9yIHR5cGVzXG4gICAgICByZXR1cm4gdGhpcy5mb3JtYXRHZW5lcmljRXJyb3JEZXRhaWxzKGVycm9yLCBmb3JtYXQpO1xuICAgIH1cblxuICAgIGNvbnN0IGRldGFpbHM6IHN0cmluZ1tdID0gW107XG4gICAgY29uc3QgZmllbGRzID0gT2JqZWN0LmVudHJpZXMoY29uZmlnLmZpZWxkcyk7XG5cbiAgICAvLyBTb3J0IGJ5IHByaW9yaXR5IChoaWdoZXIgcHJpb3JpdHkgZmlyc3QpXG4gICAgZmllbGRzLnNvcnQoKFssIGFdLCBbLCBiXSkgPT4gKGIucHJpb3JpdHkgfHwgMCkgLSAoYS5wcmlvcml0eSB8fCAwKSk7XG5cbiAgICBmb3IgKGNvbnN0IFtmaWVsZFBhdGgsIGZpZWxkQ29uZmlnXSBvZiBmaWVsZHMpIHtcbiAgICAgIC8vIENoZWNrIGNvbmRpdGlvbiBpZiBzcGVjaWZpZWRcbiAgICAgIGlmIChmaWVsZENvbmZpZy5jb25kaXRpb24gJiYgIWZpZWxkQ29uZmlnLmNvbmRpdGlvbihlcnJvcikpIHtcbiAgICAgICAgY29udGludWU7XG4gICAgICB9XG5cbiAgICAgIC8vIEdldCBmaWVsZCB2YWx1ZSB1c2luZyBkb3Qgbm90YXRpb24gKGUuZy4sICdlcnJvci5zdGFjaycpXG4gICAgICBjb25zdCB2YWx1ZSA9IHRoaXMuZ2V0TmVzdGVkVmFsdWUoZXJyb3IsIGZpZWxkUGF0aCk7XG4gICAgICBpZiAodmFsdWUgIT09IHVuZGVmaW5lZCAmJiB2YWx1ZSAhPT0gbnVsbCAmJiB2YWx1ZSAhPT0gJycpIHtcbiAgICAgICAgY29uc3QgZm9ybWF0dGVyID0gZm9ybWF0ID09PSAnaHRtbCcgPyBmaWVsZENvbmZpZy5odG1sRm9ybWF0dGVyIDogZmllbGRDb25maWcudGV4dEZvcm1hdHRlcjtcbiAgICAgICAgZGV0YWlscy5wdXNoKGZvcm1hdHRlcih2YWx1ZSwgZmllbGRQYXRoKSk7XG4gICAgICB9XG4gICAgfVxuXG4gICAgcmV0dXJuIGRldGFpbHM7XG4gIH1cblxuICAvLyBIZWxwZXIgdG8gZ2V0IG5lc3RlZCBvYmplY3QgdmFsdWVzIHVzaW5nIGRvdCBub3RhdGlvblxuICBwcml2YXRlIGdldE5lc3RlZFZhbHVlKG9iajogYW55LCBwYXRoOiBzdHJpbmcpOiBhbnkge1xuICAgIHJldHVybiBwYXRoLnNwbGl0KCcuJykucmVkdWNlKChjdXJyZW50LCBrZXkpID0+IGN1cnJlbnQ/LltrZXldLCBvYmopO1xuICB9XG5cbiAgLy8gRmFsbGJhY2sgZm9ybWF0dGVyIGZvciB1bmtub3duIGVycm9yIHR5cGVzIG9yIG1hbnVhbCBlcnJvcnNcbiAgcHJpdmF0ZSBmb3JtYXRHZW5lcmljRXJyb3JEZXRhaWxzKGVycm9yOiBTdG9yZWRFcnJvciwgZm9ybWF0OiAnaHRtbCcgfCAndGV4dCcpOiBzdHJpbmdbXSB7XG4gICAgY29uc3QgZGV0YWlsczogc3RyaW5nW10gPSBbXTtcbiAgICBjb25zdCBjb21tb25GaWVsZHMgPSBbJ2ZpbGVuYW1lJywgJ2xpbmVubycsICdjb2xubycsICdzdGFjayddO1xuXG4gICAgLy8gSGFuZGxlIGNvbW1vbiBmaWVsZHNcbiAgICBmb3IgKGNvbnN0IGZpZWxkIG9mIGNvbW1vbkZpZWxkcykge1xuICAgICAgY29uc3QgdmFsdWUgPSAoZXJyb3IgYXMgYW55KVtmaWVsZF07XG4gICAgICBpZiAodmFsdWUgIT09IHVuZGVmaW5lZCAmJiB2YWx1ZSAhPT0gbnVsbCAmJiB2YWx1ZSAhPT0gJycpIHtcbiAgICAgICAgaWYgKGZvcm1hdCA9PT0gJ2h0bWwnKSB7XG4gICAgICAgICAgaWYgKGZpZWxkID09PSAnc3RhY2snKSB7XG4gICAgICAgICAgICBjb25zdCBwcmVDbGFzcyA9ICd0ZXh0LXhzIGJnLWdyYXktODAwIHAtMyByb3VuZGVkIG92ZXJmbG93LXgtYXV0byB3aGl0ZXNwYWNlLXByZS13cmFwIGxlYWRpbmctcmVsYXhlZCc7XG4gICAgICAgICAgICBkZXRhaWxzLnB1c2goYDxkaXYgY2xhc3M9XCJtYi0zXCI+PGRpdiBjbGFzcz1cIm1iLTFcIj48c3Ryb25nPiR7dGhpcy5jYXBpdGFsaXplKGZpZWxkKX06PC9zdHJvbmc+PC9kaXY+PHByZSBjbGFzcz1cIiR7cHJlQ2xhc3N9XCI+JHt2YWx1ZX08L3ByZT48L2Rpdj5gKTtcbiAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgZGV0YWlscy5wdXNoKGA8ZGl2IGNsYXNzPVwibWItMVwiPjxzdHJvbmc+JHt0aGlzLmNhcGl0YWxpemUoZmllbGQpfTo8L3N0cm9uZz4gJHt2YWx1ZX08L2Rpdj5gKTtcbiAgICAgICAgICB9XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgZGV0YWlscy5wdXNoKGAke3RoaXMuY2FwaXRhbGl6ZShmaWVsZCl9OiAke3ZhbHVlfWApO1xuICAgICAgICB9XG4gICAgICB9XG4gICAgfVxuXG4gICAgLy8gSGFuZGxlIGFueSBhZGRpdGlvbmFsIHByb3BlcnRpZXMgZm9yIG1hbnVhbCBlcnJvcnNcbiAgICBpZiAoZXJyb3IudHlwZSA9PT0gJ21hbnVhbCcpIHtcbiAgICAgIGZvciAoY29uc3QgW2tleSwgdmFsdWVdIG9mIE9iamVjdC5lbnRyaWVzKGVycm9yKSkge1xuICAgICAgICBjb25zdCBleGNsdWRlZEZpZWxkcyA9IFsnaWQnLCAnbWVzc2FnZScsICd0eXBlJywgJ3RpbWVzdGFtcCcsIC4uLmNvbW1vbkZpZWxkc107XG4gICAgICAgIGlmICghZXhjbHVkZWRGaWVsZHMuaW5jbHVkZXMoa2V5KSAmJiB2YWx1ZSAhPT0gdW5kZWZpbmVkICYmIHZhbHVlICE9PSBudWxsICYmIHZhbHVlICE9PSAnJykge1xuICAgICAgICAgIGlmIChmb3JtYXQgPT09ICdodG1sJykge1xuICAgICAgICAgICAgY29uc3QgZm9ybWF0dGVkVmFsdWUgPSB0eXBlb2YgdmFsdWUgPT09ICdvYmplY3QnID8gSlNPTi5zdHJpbmdpZnkodmFsdWUsIG51bGwsIDIpIDogU3RyaW5nKHZhbHVlKTtcbiAgICAgICAgICAgIGlmICh0eXBlb2YgdmFsdWUgPT09ICdvYmplY3QnKSB7XG4gICAgICAgICAgICAgIGNvbnN0IHByZUNsYXNzID0gJ3RleHQteHMgYmctZ3JheS04MDAgcC0zIHJvdW5kZWQgb3ZlcmZsb3cteC1hdXRvIHdoaXRlc3BhY2UtcHJlLXdyYXAgbGVhZGluZy1yZWxheGVkJztcbiAgICAgICAgICAgICAgZGV0YWlscy5wdXNoKGA8ZGl2IGNsYXNzPVwibWItM1wiPjxkaXYgY2xhc3M9XCJtYi0xXCI+PHN0cm9uZz4ke3RoaXMuY2FwaXRhbGl6ZShrZXkpfTo8L3N0cm9uZz48L2Rpdj48cHJlIGNsYXNzPVwiJHtwcmVDbGFzc31cIj4ke2Zvcm1hdHRlZFZhbHVlfTwvcHJlPjwvZGl2PmApO1xuICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgZGV0YWlscy5wdXNoKGA8ZGl2IGNsYXNzPVwibWItMVwiPjxzdHJvbmc+JHt0aGlzLmNhcGl0YWxpemUoa2V5KX06PC9zdHJvbmc+ICR7Zm9ybWF0dGVkVmFsdWV9PC9kaXY+YCk7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIGNvbnN0IGZvcm1hdHRlZFZhbHVlID0gdHlwZW9mIHZhbHVlID09PSAnb2JqZWN0JyA/IEpTT04uc3RyaW5naWZ5KHZhbHVlLCBudWxsLCAyKSA6IFN0cmluZyh2YWx1ZSk7XG4gICAgICAgICAgICBkZXRhaWxzLnB1c2goYCR7dGhpcy5jYXBpdGFsaXplKGtleSl9OiAke2Zvcm1hdHRlZFZhbHVlfWApO1xuICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgfVxuICAgIH1cblxuICAgIHJldHVybiBkZXRhaWxzO1xuICB9XG5cbiAgLy8gSGVscGVyIHRvIGNhcGl0YWxpemUgZmlyc3QgbGV0dGVyXG4gIHByaXZhdGUgY2FwaXRhbGl6ZShzdHI6IHN0cmluZyk6IHN0cmluZyB7XG4gICAgcmV0dXJuIHN0ci5jaGFyQXQoMCkudG9VcHBlckNhc2UoKSArIHN0ci5zbGljZSgxKTtcbiAgfVxuXG4gIGZvcm1hdFRlY2huaWNhbERldGFpbHMoZXJyb3I6IFN0b3JlZEVycm9yKTogc3RyaW5nIHtcbiAgICBjb25zdCBkZXRhaWxzID0gW2A8ZGl2IGNsYXNzPSdtYi0xJz48c3Ryb25nPlBhZ2UgUGF0aDo8L3N0cm9uZz4gJHt3aW5kb3cubG9jYXRpb24ucGF0aG5hbWV9PC9kaXY+YF07XG5cbiAgICAvLyBVc2UgdGhlIHVuaWZpZWQgZm9ybWF0dGluZyBzeXN0ZW1cbiAgICBjb25zdCB0eXBlU3BlY2lmaWNEZXRhaWxzID0gdGhpcy5mb3JtYXRFcnJvckRldGFpbHMoZXJyb3IsICdodG1sJyk7XG4gICAgZGV0YWlscy5wdXNoKC4uLnR5cGVTcGVjaWZpY0RldGFpbHMpO1xuXG4gICAgcmV0dXJuIGRldGFpbHMuam9pbignJyk7XG4gIH1cblxuICBjb3B5RXJyb3JUb0NsaXBib2FyZChlcnJvcklkOiBzdHJpbmcpOiB2b2lkIHtcbiAgICBjb25zdCBlcnJvciA9IHRoaXMuZXJyb3JzLmZpbmQoZSA9PiBlLmlkID09PSBlcnJvcklkKTtcbiAgICBpZiAoIWVycm9yKSByZXR1cm47XG5cbiAgICBjb25zdCBlcnJvclJlcG9ydCA9IHRoaXMuZ2VuZXJhdGVFcnJvclJlcG9ydChlcnJvcik7XG4gICAgY29uc3QgYnV0dG9uID0gZG9jdW1lbnQucXVlcnlTZWxlY3RvcihgW2RhdGEtZXJyb3ItaWQ9XCIke2Vycm9ySWR9XCJdIC5jb3B5LWVycm9yYCkgYXMgSFRNTEVsZW1lbnQ7XG5cbiAgICBpZiAoIXdpbmRvdy5jb3B5VG9DbGlwYm9hcmQpIHtcbiAgICAgIHRoaXMub3JpZ2luYWxDb25zb2xlRXJyb3IoJ3dpbmRvdy5jb3B5VG9DbGlwYm9hcmQgbm90IGZvdW5kJyk7XG4gICAgICBhbGVydChgQ29weSBmYWlsZWQuIEVycm9yIGRldGFpbHM6XFxuJHsgIGVycm9yUmVwb3J0fWApO1xuICAgICAgcmV0dXJuO1xuICAgIH1cblxuICAgIHdpbmRvdy5jb3B5VG9DbGlwYm9hcmQoZXJyb3JSZXBvcnQpLnRoZW4oKCkgPT4ge1xuICAgICAgaWYgKCFidXR0b24pIHJldHVybjtcbiAgICAgIC8vIFNob3cgc3VjY2VzcyBmZWVkYmFja1xuICAgICAgY29uc3Qgb3JpZ2luYWxUZXh0ID0gYnV0dG9uLnRleHRDb250ZW50O1xuICAgICAgYnV0dG9uLnRleHRDb250ZW50ID0gJ0NvcGllZCc7XG4gICAgICBidXR0b24uY2xhc3NOYW1lID0gYnV0dG9uLmNsYXNzTmFtZS5yZXBsYWNlKCd0ZXh0LWJsdWUtNDAwJywgJ3RleHQtZ3JlZW4tNDAwJyk7XG5cbiAgICAgIHNldFRpbWVvdXQoKCkgPT4ge1xuICAgICAgICBidXR0b24udGV4dENvbnRlbnQgPSBvcmlnaW5hbFRleHQ7XG4gICAgICAgIGJ1dHRvbi5jbGFzc05hbWUgPSBidXR0b24uY2xhc3NOYW1lLnJlcGxhY2UoJ3RleHQtZ3JlZW4tNDAwJywgJ3RleHQtYmx1ZS00MDAnKTtcbiAgICAgIH0sIDIwMDApO1xuICAgIH0pLmNhdGNoKGVyciA9PiB7XG4gICAgICB0aGlzLm9yaWdpbmFsQ29uc29sZUVycm9yKCdGYWlsZWQgdG8gY29weSBlcnJvcjonLCBlcnIpO1xuICAgICAgLy8gRmFsbGJhY2s6IHNob3cgZXJyb3IgZGV0YWlscyBpbiBhIG1vZGFsIG9yIGFsZXJ0XG4gICAgICBhbGVydChgQ29weSBmYWlsZWQuIEVycm9yIGRldGFpbHM6XFxuJHsgIGVycm9yUmVwb3J0fWApO1xuICAgIH0pO1xuICB9XG5cbiAgY29weUFsbEVycm9yc1RvQ2xpcGJvYXJkKCk6IHZvaWQge1xuICAgIGlmICh0aGlzLmVycm9ycy5sZW5ndGggPT09IDApIHJldHVybjtcblxuICAgIGNvbnN0IGFsbEVycm9yc1JlcG9ydCA9IHRoaXMuZ2VuZXJhdGVBbGxFcnJvcnNSZXBvcnQoKTtcbiAgICBjb25zdCBidXR0b24gPSBkb2N1bWVudC5nZXRFbGVtZW50QnlJZCgnY29weS1hbGwtZXJyb3JzJykgYXMgSFRNTEVsZW1lbnQ7XG5cbiAgICBpZiAoIXdpbmRvdy5jb3B5VG9DbGlwYm9hcmQpIHtcbiAgICAgIHRoaXMub3JpZ2luYWxDb25zb2xlRXJyb3IoJ3dpbmRvdy5jb3B5VG9DbGlwYm9hcmQgbm90IGZvdW5kJyk7XG4gICAgICBhbGVydChgQ29weSBmYWlsZWQuIEVycm9yIGRldGFpbHM6XFxuJHthbGxFcnJvcnNSZXBvcnR9YCk7XG4gICAgICByZXR1cm47XG4gICAgfVxuXG4gICAgd2luZG93LmNvcHlUb0NsaXBib2FyZChhbGxFcnJvcnNSZXBvcnQpLnRoZW4oKCkgPT4ge1xuICAgICAgaWYgKCFidXR0b24pIHJldHVybjtcbiAgICAgIC8vIFNob3cgc3VjY2VzcyBmZWVkYmFja1xuICAgICAgY29uc3Qgb3JpZ2luYWxUZXh0ID0gYnV0dG9uLnRleHRDb250ZW50O1xuICAgICAgYnV0dG9uLnRleHRDb250ZW50ID0gJ0NvcGllZCc7XG4gICAgICBidXR0b24uY2xhc3NOYW1lID0gYnV0dG9uLmNsYXNzTmFtZS5yZXBsYWNlKCd0ZXh0LXllbGxvdy00MDAnLCAndGV4dC1ncmVlbi00MDAnKTtcblxuICAgICAgc2V0VGltZW91dCgoKSA9PiB7XG4gICAgICAgIGJ1dHRvbi50ZXh0Q29udGVudCA9IG9yaWdpbmFsVGV4dDtcbiAgICAgICAgYnV0dG9uLmNsYXNzTmFtZSA9IGJ1dHRvbi5jbGFzc05hbWUucmVwbGFjZSgndGV4dC1ncmVlbi00MDAnLCAndGV4dC15ZWxsb3ctNDAwJyk7XG4gICAgICB9LCAyMDAwKTtcbiAgICB9KS5jYXRjaChlcnIgPT4ge1xuICAgICAgdGhpcy5vcmlnaW5hbENvbnNvbGVFcnJvcignRmFpbGVkIHRvIGNvcHkgYWxsIGVycm9yczonLCBlcnIpO1xuICAgICAgLy8gRmFsbGJhY2s6IHNob3cgZXJyb3IgZGV0YWlscyBpbiBhIG1vZGFsIG9yIGFsZXJ0XG4gICAgICBhbGVydChgQ29weSBmYWlsZWQuIEVycm9yIGRldGFpbHM6XFxuJHsgIGFsbEVycm9yc1JlcG9ydH1gKTtcbiAgICB9KTtcbiAgfVxuXG4gIGdlbmVyYXRlQWxsRXJyb3JzUmVwb3J0KCk6IHN0cmluZyB7XG4gICAgY29uc3QgbWF4RXJyb3JzID0gMzsgLy8gU2hvdyBvbmx5IGxhdGVzdCAzIGVycm9yc1xuICAgIGNvbnN0IG1heFJlc3BvbnNlQm9keUxlbmd0aCA9IDQwMDsgLy8gTGltaXQgcmVzcG9uc2UgYm9keSBsZW5ndGhcbiAgICBjb25zdCBtYXhUb3RhbExlbmd0aCA9IDIwMDA7IC8vIFRvdGFsIGNoYXJhY3RlciBsaW1pdFxuXG4gICAgY29uc3QgcmVjZW50RXJyb3JzID0gdGhpcy5lcnJvcnMuc2xpY2UoMCwgbWF4RXJyb3JzKTtcbiAgICBjb25zdCB0b3RhbEVycm9ycyA9IHRoaXMuZXJyb3JzLnJlZHVjZSgoc3VtLCBlcnJvcikgPT4gc3VtICsgZXJyb3IuY291bnQsIDApO1xuXG4gICAgbGV0IHJlcG9ydCA9IGBGcm9udGVuZCBFcnJvciBSZXBvcnQgLSBSZWNlbnQgRXJyb3JzXG5cdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcdTI1NTBcblRpbWU6ICR7bmV3IERhdGUoKS50b0xvY2FsZVN0cmluZygpfVxuUGFnZSBQYXRoOiAke3dpbmRvdy5sb2NhdGlvbi5wYXRobmFtZX1cblRvdGFsIEVycm9yczogJHt0b3RhbEVycm9yc30gKHNob3dpbmcgbGF0ZXN0ICR7cmVjZW50RXJyb3JzLmxlbmd0aH0pXG4ke3RoaXMuZm9ybWF0TGFzdFVzZXJBY3Rpb24oKX1cbmA7XG5cbiAgICBmb3IgKGxldCBpbmRleCA9IDA7IGluZGV4IDwgcmVjZW50RXJyb3JzLmxlbmd0aDsgaW5kZXgrKykge1xuICAgICAgY29uc3QgZXJyb3IgPSByZWNlbnRFcnJvcnNbaW5kZXhdO1xuICAgICAgY29uc3QgY291bnRUZXh0ID0gZXJyb3IuY291bnQgPiAxID8gYCAoJHtlcnJvci5jb3VudH14KWAgOiAnJztcbiAgICAgIHJlcG9ydCArPSBgRXJyb3IgJHtpbmRleCArIDF9JHtjb3VudFRleHR9OlxuXHUyNTAwXHUyNTAwXHUyNTAwXHUyNTAwXHUyNTAwXHUyNTAwXHUyNTAwXHUyNTAwXHUyNTAwXHUyNTAwXHUyNTAwXHUyNTAwXHUyNTAwXG4ke2Vycm9yLm1lc3NhZ2V9XG5cblRlY2huaWNhbCBEZXRhaWxzOmA7XG5cbiAgICAgIC8vIFVzZSB0aGUgdW5pZmllZCBmb3JtYXR0aW5nIHN5c3RlbSBmb3IgdGV4dCBvdXRwdXRcbiAgICAgIGNvbnN0IHR5cGVTcGVjaWZpY0RldGFpbHMgPSB0aGlzLmZvcm1hdEVycm9yRGV0YWlscyhlcnJvciwgJ3RleHQnKTtcbiAgICAgIGlmICh0eXBlU3BlY2lmaWNEZXRhaWxzLmxlbmd0aCA+IDApIHtcbiAgICAgICAgLy8gVHJ1bmNhdGUgbG9uZyBkZXRhaWxzIHRvIHJlc3BlY3QgbGVuZ3RoIGxpbWl0c1xuICAgICAgICBjb25zdCB0cnVuY2F0ZWREZXRhaWxzID0gdHlwZVNwZWNpZmljRGV0YWlscy5tYXAoZGV0YWlsID0+XG4gICAgICAgICAgdGhpcy50cnVuY2F0ZVRleHQoZGV0YWlsLCBtYXhSZXNwb25zZUJvZHlMZW5ndGgpXG4gICAgICAgICk7XG4gICAgICAgIHJlcG9ydCArPSBgXFxuJHsgIHRydW5jYXRlZERldGFpbHMuam9pbignXFxuJyl9YDtcbiAgICAgIH1cblxuICAgICAgLy8gQWRkIHRpbWVzdGFtcFxuICAgICAgcmVwb3J0ICs9IGBcXG5GaXJzdCBvY2N1cnJlZDogJHtuZXcgRGF0ZShlcnJvci50aW1lc3RhbXApLnRvTG9jYWxlU3RyaW5nKCl9YDtcbiAgICAgIGlmIChlcnJvci5sYXN0T2NjdXJyZWQgJiYgZXJyb3IubGFzdE9jY3VycmVkICE9PSBlcnJvci50aW1lc3RhbXApIHtcbiAgICAgICAgcmVwb3J0ICs9IGBcXG5MYXN0IG9jY3VycmVkOiAke25ldyBEYXRlKGVycm9yLmxhc3RPY2N1cnJlZCkudG9Mb2NhbGVTdHJpbmcoKX1gO1xuICAgICAgfVxuXG4gICAgICByZXBvcnQgKz0gJ1xcblxcbic7XG5cbiAgICAgIC8vIENoZWNrIGlmIGV4Y2VlZGluZyB0b3RhbCBjaGFyYWN0ZXIgbGltaXRcbiAgICAgIGlmIChyZXBvcnQubGVuZ3RoID4gbWF4VG90YWxMZW5ndGggLSAxMDApIHsgLy8gUmVzZXJ2ZSAxMDAgY2hhcnMgZm9yIGVuZGluZ1xuICAgICAgICByZXBvcnQgKz0gYFtSZXBvcnQgdHJ1bmNhdGVkIGR1ZSB0byBsZW5ndGggbGltaXRdYDtcbiAgICAgICAgYnJlYWs7XG4gICAgICB9XG4gICAgfVxuXG4gICAgLy8gRW5zdXJlIHRvdGFsIGxlbmd0aCBkb2Vzbid0IGV4Y2VlZCBsaW1pdFxuICAgIGlmIChyZXBvcnQubGVuZ3RoID4gbWF4VG90YWxMZW5ndGggLSA1MCkge1xuICAgICAgcmVwb3J0ID0gYCR7cmVwb3J0LnN1YnN0cmluZygwLCBtYXhUb3RhbExlbmd0aCAtIDUwKSAgfS4uLlxcblxcbmA7XG4gICAgfVxuXG4gICAgcmVwb3J0ICs9ICdQbGVhc2UgaGVscCBtZSBhbmFseXplIGFuZCBmaXggdGhlc2UgaXNzdWVzLic7XG4gICAgcmV0dXJuIHJlcG9ydDtcbiAgfVxuXG4gIGdlbmVyYXRlRXJyb3JSZXBvcnQoZXJyb3I6IFN0b3JlZEVycm9yKTogc3RyaW5nIHtcbiAgICBjb25zdCBtYXhEZXRhaWxMZW5ndGggPSA4MDA7IC8vIExpbWl0IGVhY2ggZGV0YWlsIGZpZWxkIGxlbmd0aFxuICAgIGNvbnN0IG1heFRvdGFsTGVuZ3RoID0gMzAwMDsgLy8gVG90YWwgY2hhcmFjdGVyIGxpbWl0IGZvciBzaW5nbGUgZXJyb3JcblxuICAgIGxldCByZXBvcnQgPSBgRnJvbnRlbmQgRXJyb3IgUmVwb3J0XG5cdTI1MDBcdTI1MDBcdTI1MDBcdTI1MDBcdTI1MDBcdTI1MDBcdTI1MDBcdTI1MDBcdTI1MDBcdTI1MDBcdTI1MDBcdTI1MDBcdTI1MDBcblRpbWU6ICR7bmV3IERhdGUoZXJyb3IudGltZXN0YW1wKS50b0xvY2FsZVN0cmluZygpfVxuUGFnZSBQYXRoOiAke3dpbmRvdy5sb2NhdGlvbi5wYXRobmFtZX1cbiR7dGhpcy5mb3JtYXRMYXN0VXNlckFjdGlvbigpfVxuVGVjaG5pY2FsIERldGFpbHM6XG4ke3RoaXMudHJ1bmNhdGVUZXh0KGVycm9yLm1lc3NhZ2UsIG1heERldGFpbExlbmd0aCl9YDtcblxuICAgIC8vIFVzZSB0aGUgdW5pZmllZCBmb3JtYXR0aW5nIHN5c3RlbSBmb3IgdGV4dCBvdXRwdXRcbiAgICBjb25zdCB0eXBlU3BlY2lmaWNEZXRhaWxzID0gdGhpcy5mb3JtYXRFcnJvckRldGFpbHMoZXJyb3IsICd0ZXh0Jyk7XG4gICAgaWYgKHR5cGVTcGVjaWZpY0RldGFpbHMubGVuZ3RoID4gMCkge1xuICAgICAgLy8gVHJ1bmNhdGUgbG9uZyBkZXRhaWxzIHRvIHJlc3BlY3QgbGVuZ3RoIGxpbWl0c1xuICAgICAgY29uc3QgdHJ1bmNhdGVkRGV0YWlscyA9IHR5cGVTcGVjaWZpY0RldGFpbHMubWFwKGRldGFpbCA9PlxuICAgICAgICB0aGlzLnRydW5jYXRlVGV4dChkZXRhaWwsIG1heERldGFpbExlbmd0aClcbiAgICAgICk7XG4gICAgICByZXBvcnQgKz0gYFxcblxcbiR7ICB0cnVuY2F0ZWREZXRhaWxzLmpvaW4oJ1xcbicpfWA7XG4gICAgfVxuXG4gICAgLy8gRW5zdXJlIHRvdGFsIGxlbmd0aCBkb2Vzbid0IGV4Y2VlZCBsaW1pdFxuICAgIGlmIChyZXBvcnQubGVuZ3RoID4gbWF4VG90YWxMZW5ndGggLSAxMDApIHtcbiAgICAgIHJlcG9ydCA9IGAke3JlcG9ydC5zdWJzdHJpbmcoMCwgbWF4VG90YWxMZW5ndGggLSAxMDApfS4uLlxcblxcbltSZXBvcnQgdHJ1bmNhdGVkIGR1ZSB0byBsZW5ndGggbGltaXRdYDtcbiAgICB9XG5cbiAgICByZXBvcnQgKz0gYFxcblxcblBsZWFzZSBoZWxwIG1lIGFuYWx5emUgYW5kIGZpeCB0aGlzIGlzc3VlLmA7XG4gICAgcmV0dXJuIHJlcG9ydDtcbiAgfVxuXG4gIHJlbW92ZUVycm9yKGVycm9ySWQ6IHN0cmluZyk6IHZvaWQge1xuICAgIGNvbnN0IGVycm9ySW5kZXggPSB0aGlzLmVycm9ycy5maW5kSW5kZXgoZSA9PiBlLmlkID09PSBlcnJvcklkKTtcbiAgICBpZiAoZXJyb3JJbmRleCA9PT0gLTEpIHJldHVybjtcblxuICAgIGNvbnN0IGVycm9yID0gdGhpcy5lcnJvcnNbZXJyb3JJbmRleF07XG4gICAgaWYgKGVycm9yLnR5cGUgaW4gdGhpcy5lcnJvckNvdW50cykge1xuICAgICAgdGhpcy5lcnJvckNvdW50c1tlcnJvci50eXBlIGFzIGtleW9mIEVycm9yQ291bnRzXSA9IE1hdGgubWF4KDAsICh0aGlzLmVycm9yQ291bnRzW2Vycm9yLnR5cGUgYXMga2V5b2YgRXJyb3JDb3VudHNdIHx8IDApIC0gZXJyb3IuY291bnQpO1xuICAgIH1cbiAgICB0aGlzLmVycm9ycy5zcGxpY2UoZXJyb3JJbmRleCwgMSk7XG5cbiAgICB0aGlzLnVwZGF0ZVN0YXR1c0JhcigpO1xuICAgIHRoaXMudXBkYXRlRXJyb3JMaXN0KCk7XG5cbiAgICAvLyBIaWRlIHN0YXR1cyBiYXIgaWYgbm8gZXJyb3JzXG4gICAgaWYgKHRoaXMuZXJyb3JzLmxlbmd0aCA9PT0gMCkge1xuICAgICAgdGhpcy5oaWRlU3RhdHVzQmFyKCk7XG4gICAgfVxuICB9XG5cbiAgY2xlYXJBbGxFcnJvcnMoKSB7XG4gICAgdGhpcy5lcnJvcnMgPSBbXTtcbiAgICB0aGlzLmVycm9yQ291bnRzID0ge1xuICAgICAgamF2YXNjcmlwdDogMCxcbiAgICAgIGludGVyYWN0aW9uOiAwLFxuICAgICAgcHJvbWlzZTogMCxcbiAgICAgIGh0dHA6IDAsXG4gICAgICBhY3Rpb25jYWJsZTogMCxcbiAgICAgIGFzeW5jam9iOiAwLFxuICAgICAgbWFudWFsOiAwLFxuICAgICAgc3RpbXVsdXM6IDBcbiAgICB9O1xuXG4gICAgdGhpcy51cGRhdGVTdGF0dXNCYXIoKTtcbiAgICB0aGlzLnVwZGF0ZUVycm9yTGlzdCgpO1xuICAgIHRoaXMuaGlkZVN0YXR1c0JhcigpO1xuICB9XG5cbiAgc2hvd1N0YXR1c0JhcigpOiB2b2lkIHtcbiAgICBpZiAodGhpcy5zdGF0dXNCYXIpIHtcbiAgICAgIHRoaXMuc3RhdHVzQmFyLnN0eWxlLmRpc3BsYXkgPSAnYmxvY2snO1xuICAgIH1cbiAgfVxuXG4gIGhpZGVTdGF0dXNCYXIoKTogdm9pZCB7XG4gICAgaWYgKHRoaXMuc3RhdHVzQmFyKSB7XG4gICAgICB0aGlzLnN0YXR1c0Jhci5zdHlsZS5kaXNwbGF5ID0gJ25vbmUnO1xuICAgICAgdGhpcy5pc0V4cGFuZGVkID0gZmFsc2U7XG4gICAgICBjb25zdCBlcnJvckRldGFpbHMgPSBkb2N1bWVudC5nZXRFbGVtZW50QnlJZCgnZXJyb3ItZGV0YWlscycpO1xuICAgICAgY29uc3QgdG9nZ2xlVGV4dCA9IGRvY3VtZW50LmdldEVsZW1lbnRCeUlkKCd0b2dnbGUtdGV4dCcpO1xuICAgICAgY29uc3QgdG9nZ2xlSWNvbiA9IGRvY3VtZW50LmdldEVsZW1lbnRCeUlkKCd0b2dnbGUtaWNvbicpO1xuXG4gICAgICBpZiAoZXJyb3JEZXRhaWxzKSBlcnJvckRldGFpbHMuc3R5bGUuZGlzcGxheSA9ICdub25lJztcbiAgICAgIGlmICh0b2dnbGVUZXh0KSB0b2dnbGVUZXh0LnRleHRDb250ZW50ID0gJ1Nob3cnO1xuICAgICAgaWYgKHRvZ2dsZUljb24pIHRvZ2dsZUljb24udGV4dENvbnRlbnQgPSAnXHUyMTkxJztcbiAgICB9XG4gIH1cblxuICBmbGFzaE5ld0Vycm9yKCk6IHZvaWQge1xuICAgIC8vIEZsYXNoIHRoZSBzdGF0dXMgYmFyIHRvIGluZGljYXRlIG5ldyBlcnJvclxuICAgIGlmICh0aGlzLnN0YXR1c0Jhcikge1xuICAgICAgdGhpcy5zdGF0dXNCYXIuc3R5bGUuYm9yZGVyVG9wQ29sb3IgPSAnI2VmNDQ0NCc7XG4gICAgICB0aGlzLnN0YXR1c0Jhci5zdHlsZS5ib3JkZXJUb3BXaWR0aCA9ICcycHgnO1xuXG4gICAgICBzZXRUaW1lb3V0KCgpID0+IHtcbiAgICAgICAgaWYgKHRoaXMuc3RhdHVzQmFyKSB7XG4gICAgICAgICAgdGhpcy5zdGF0dXNCYXIuc3R5bGUuYm9yZGVyVG9wQ29sb3IgPSAnIzM3NDE1MSc7XG4gICAgICAgICAgdGhpcy5zdGF0dXNCYXIuc3R5bGUuYm9yZGVyVG9wV2lkdGggPSAnMXB4JztcbiAgICAgICAgfVxuICAgICAgfSwgMTAwMCk7XG4gICAgfVxuICB9XG5cbiAgc2FuaXRpemVNZXNzYWdlKG1lc3NhZ2U6IHN0cmluZyk6IHN0cmluZyB7XG4gICAgaWYgKCFtZXNzYWdlKSByZXR1cm4gJ1Vua25vd24gZXJyb3InO1xuXG4gICAgY29uc3QgY2xlYW5NZXNzYWdlID0gbWVzc2FnZVxuICAgICAgLnJlcGxhY2UoLyYvZywgJyZhbXA7JykgICAvLyBFc2NhcGUgJiBmaXJzdFxuICAgICAgLnJlcGxhY2UoLzwvZywgJyZsdDsnKSAgICAvLyBFc2NhcGUgPFxuICAgICAgLnJlcGxhY2UoLz4vZywgJyZndDsnKSAgICAvLyBFc2NhcGUgPlxuICAgICAgLnJlcGxhY2UoL1wiL2csICcmcXVvdDsnKSAgLy8gRXNjYXBlIFwiXG4gICAgICAucmVwbGFjZSgvJy9nLCAnJiMzOTsnKSAgIC8vIEVzY2FwZSAnXG4gICAgICAucmVwbGFjZSgvXFxuL2csICcgJykgICAgICAvLyBSZXBsYWNlIG5ld2xpbmVzIHdpdGggc3BhY2VzXG4gICAgICAudHJpbSgpO1xuXG4gICAgcmV0dXJuIGNsZWFuTWVzc2FnZS5sZW5ndGggPiAxMDBcbiAgICAgID8gYCR7Y2xlYW5NZXNzYWdlLnN1YnN0cmluZygwLCAxMDApICB9Li4uYFxuICAgICAgOiBjbGVhbk1lc3NhZ2U7XG4gIH1cblxuICB0cnVuY2F0ZVRleHQodGV4dDogc3RyaW5nLCBtYXhMZW5ndGg6IG51bWJlcik6IHN0cmluZyB7XG4gICAgaWYgKCF0ZXh0KSByZXR1cm4gJyc7XG4gICAgaWYgKHRleHQubGVuZ3RoIDw9IG1heExlbmd0aCkgcmV0dXJuIHRleHQ7XG4gICAgcmV0dXJuIGAke3RleHQuc3Vic3RyaW5nKDAsIG1heExlbmd0aCkgIH0uLi4gW3RydW5jYXRlZF1gO1xuICB9XG5cbiAgZXh0cmFjdEZpbGVuYW1lKGZpbGVwYXRoOiBzdHJpbmcpOiBzdHJpbmcge1xuICAgIGlmICghZmlsZXBhdGgpIHJldHVybiAnJztcbiAgICByZXR1cm4gZmlsZXBhdGguc3BsaXQoJy8nKS5wb3AoKSB8fCBmaWxlcGF0aDtcbiAgfVxuXG4gIGNsZWFudXBEZWJvdW5jZU1hcCgpIHtcbiAgICAvLyBDbGVhbiB1cCBkZWJvdW5jZSBlbnRyaWVzIG9sZGVyIHRoYW4gZGVib3VuY2VUaW1lICogMTBcbiAgICBjb25zdCBjdXRvZmZUaW1lID0gRGF0ZS5ub3coKSAtICh0aGlzLmRlYm91bmNlVGltZSAqIDEwKTtcbiAgICBmb3IgKGNvbnN0IFtrZXksIHRpbWVzdGFtcF0gb2YgdGhpcy5yZWNlbnRFcnJvcnNEZWJvdW5jZS5lbnRyaWVzKCkpIHtcbiAgICAgIGlmICh0aW1lc3RhbXAgPCBjdXRvZmZUaW1lKSB7XG4gICAgICAgIHRoaXMucmVjZW50RXJyb3JzRGVib3VuY2UuZGVsZXRlKGtleSk7XG4gICAgICB9XG4gICAgfVxuICB9XG5cbiAgZm9ybWF0TGFzdFVzZXJBY3Rpb24oKTogc3RyaW5nIHtcbiAgICBpZiAoIXRoaXMubGFzdFVzZXJBY3Rpb24pIHJldHVybiAnJztcblxuICAgIGNvbnN0IHRpbWVEaWZmID0gRGF0ZS5ub3coKSAtIHRoaXMubGFzdFVzZXJBY3Rpb24udGltZXN0YW1wO1xuICAgIC8vIE9ubHkgc2hvdyBpZiB3aXRoaW4gNSBzZWNvbmRzXG4gICAgaWYgKHRpbWVEaWZmID4gNTAwMCkgcmV0dXJuICcnO1xuXG4gICAgY29uc3Qgc2Vjb25kc0FnbyA9ICh0aW1lRGlmZiAvIDEwMDApLnRvRml4ZWQoMSk7XG4gICAgbGV0IGFjdGlvbkRlc2MgPSBgTGFzdCBVc2VyIEFjdGlvbjogJHt0aGlzLmxhc3RVc2VyQWN0aW9uLnR5cGV9ICR7dGhpcy5sYXN0VXNlckFjdGlvbi5lbGVtZW50fWA7XG5cbiAgICBpZiAodGhpcy5sYXN0VXNlckFjdGlvbi50ZXh0KSB7XG4gICAgICBhY3Rpb25EZXNjICs9IGAgXCIke3RoaXMubGFzdFVzZXJBY3Rpb24udGV4dH1cImA7XG4gICAgfVxuXG4gICAgaWYgKHRoaXMubGFzdFVzZXJBY3Rpb24uc3RpbXVsdXNBY3Rpb24pIHtcbiAgICAgIGFjdGlvbkRlc2MgKz0gYCBbZGF0YS1hY3Rpb249XCIke3RoaXMubGFzdFVzZXJBY3Rpb24uc3RpbXVsdXNBY3Rpb259XCJdYDtcbiAgICB9XG5cbiAgICBpZiAodGhpcy5sYXN0VXNlckFjdGlvbi5zdGltdWx1c0NvbnRyb2xsZXIpIHtcbiAgICAgIGFjdGlvbkRlc2MgKz0gYCBbY29udHJvbGxlcj1cIiR7dGhpcy5sYXN0VXNlckFjdGlvbi5zdGltdWx1c0NvbnRyb2xsZXJ9XCJdYDtcbiAgICB9XG5cbiAgICBhY3Rpb25EZXNjICs9IGAgKCR7c2Vjb25kc0Fnb31zIGFnbylgO1xuXG4gICAgcmV0dXJuIGAke2FjdGlvbkRlc2N9XFxuYDtcbiAgfVxuXG4gIC8vIFB1YmxpYyBBUEkgbWV0aG9kc1xuICBnZXRFcnJvcnMoKTogU3RvcmVkRXJyb3JbXSB7XG4gICAgcmV0dXJuIHRoaXMuZXJyb3JzO1xuICB9XG5cbiAgcmVwb3J0RXJyb3IobWVzc2FnZTogc3RyaW5nLCBjb250ZXh0OiBQYXJ0aWFsPEVycm9ySW5mbz4gPSB7fSk6IHZvaWQge1xuICAgIHRoaXMuaGFuZGxlRXJyb3Ioe1xuICAgICAgbWVzc2FnZTogbWVzc2FnZSxcbiAgICAgIHR5cGU6ICdtYW51YWwnLFxuICAgICAgdGltZXN0YW1wOiBuZXcgRGF0ZSgpLnRvSVNPU3RyaW5nKCksXG4gICAgICAuLi5jb250ZXh0XG4gICAgfSk7XG4gIH1cblxuICAvLyBBY3Rpb25DYWJsZSBzcGVjaWZpYyBlcnJvciBjYXB0dXJpbmdcbiAgY2FwdHVyZUFjdGlvbkNhYmxlRXJyb3IoZXJyb3JEYXRhOiBhbnkpOiB2b2lkIHtcbiAgICB0aGlzLmVycm9yQ291bnRzLmFjdGlvbmNhYmxlKys7XG5cbiAgICBjb25zdCBlcnJvckluZm86IEFjdGlvbkNhYmxlRXJyb3JJbmZvID0ge1xuICAgICAgdHlwZTogJ2FjdGlvbmNhYmxlJyxcbiAgICAgIG1lc3NhZ2U6IGVycm9yRGF0YS5tZXNzYWdlIHx8ICdBY3Rpb25DYWJsZSBlcnJvciBvY2N1cnJlZCcsXG4gICAgICB0aW1lc3RhbXA6IG5ldyBEYXRlKCkudG9JU09TdHJpbmcoKSxcbiAgICAgIGNoYW5uZWw6IGVycm9yRGF0YS5jaGFubmVsIHx8ICd1bmtub3duJyxcbiAgICAgIGFjdGlvbjogZXJyb3JEYXRhLmFjdGlvbiB8fCAndW5rbm93bicsXG4gICAgICBmaWxlbmFtZTogYGNoYW5uZWw6ICR7ZXJyb3JEYXRhLmNoYW5uZWx9YCxcbiAgICAgIGxpbmVubzogMCxcbiAgICAgIGRldGFpbHM6IGVycm9yRGF0YVxuICAgIH07XG5cbiAgICB0aGlzLmhhbmRsZUVycm9yKGVycm9ySW5mbyk7XG4gIH1cblxuICAvLyBTb3VyY2UgTWFwIHJlbGF0ZWQgbWV0aG9kc1xuICBwcml2YXRlIGFzeW5jIGdldFNvdXJjZU1hcENvbnN1bWVyKGZpbGVVcmw6IHN0cmluZyk6IFByb21pc2U8U291cmNlTWFwQ29uc3VtZXIgfCBudWxsPiB7XG4gICAgLy8gQ2hlY2sgY2FjaGUgZmlyc3RcbiAgICBpZiAodGhpcy5zb3VyY2VNYXBDYWNoZS5oYXMoZmlsZVVybCkpIHtcbiAgICAgIHJldHVybiB0aGlzLnNvdXJjZU1hcENhY2hlLmdldChmaWxlVXJsKSE7XG4gICAgfVxuXG4gICAgLy8gQ2hlY2sgaWYgYWxyZWFkeSBwZW5kaW5nXG4gICAgaWYgKHRoaXMuc291cmNlTWFwUGVuZGluZy5oYXMoZmlsZVVybCkpIHtcbiAgICAgIHJldHVybiB0aGlzLnNvdXJjZU1hcFBlbmRpbmcuZ2V0KGZpbGVVcmwpITtcbiAgICB9XG5cbiAgICAvLyBDcmVhdGUgbmV3IHByb21pc2VcbiAgICBjb25zdCBwcm9taXNlID0gdGhpcy5sb2FkU291cmNlTWFwKGZpbGVVcmwpO1xuICAgIHRoaXMuc291cmNlTWFwUGVuZGluZy5zZXQoZmlsZVVybCwgcHJvbWlzZSk7XG5cbiAgICBjb25zdCBjb25zdW1lciA9IGF3YWl0IHByb21pc2U7XG4gICAgdGhpcy5zb3VyY2VNYXBQZW5kaW5nLmRlbGV0ZShmaWxlVXJsKTtcblxuICAgIGlmIChjb25zdW1lcikge1xuICAgICAgdGhpcy5zb3VyY2VNYXBDYWNoZS5zZXQoZmlsZVVybCwgY29uc3VtZXIpO1xuICAgIH1cblxuICAgIHJldHVybiBjb25zdW1lcjtcbiAgfVxuXG4gIHByaXZhdGUgYXN5bmMgbG9hZFNvdXJjZU1hcChmaWxlVXJsOiBzdHJpbmcpOiBQcm9taXNlPFNvdXJjZU1hcENvbnN1bWVyIHwgbnVsbD4ge1xuICAgIHRyeSB7XG4gICAgICBjb25zdCByZXNwb25zZSA9IGF3YWl0IGZldGNoKGZpbGVVcmwpO1xuICAgICAgY29uc3Qgc291cmNlQ29kZSA9IGF3YWl0IHJlc3BvbnNlLnRleHQoKTtcblxuICAgICAgLy8gRXh0cmFjdCBpbmxpbmUgc291cmNlIG1hcCAoYmFzZTY0IGVuY29kZWQpXG4gICAgICBjb25zdCBzb3VyY2VNYXBNYXRjaCA9IHNvdXJjZUNvZGUubWF0Y2goL1xcL1xcLyMgc291cmNlTWFwcGluZ1VSTD1kYXRhOmFwcGxpY2F0aW9uXFwvanNvbjtiYXNlNjQsKFteXFxzXSspLyk7XG4gICAgICBpZiAoIXNvdXJjZU1hcE1hdGNoKSB7XG4gICAgICAgIHJldHVybiBudWxsO1xuICAgICAgfVxuXG4gICAgICBjb25zdCBiYXNlNjRTb3VyY2VNYXAgPSBzb3VyY2VNYXBNYXRjaFsxXTtcbiAgICAgIGNvbnN0IHNvdXJjZU1hcEpzb24gPSBhdG9iKGJhc2U2NFNvdXJjZU1hcCk7XG4gICAgICBjb25zdCBzb3VyY2VNYXAgPSBKU09OLnBhcnNlKHNvdXJjZU1hcEpzb24pO1xuXG4gICAgICByZXR1cm4gYXdhaXQgbmV3IFNvdXJjZU1hcENvbnN1bWVyKHNvdXJjZU1hcCk7XG4gICAgfSBjYXRjaCAoZXJyb3IpIHtcbiAgICAgIHRoaXMub3JpZ2luYWxDb25zb2xlRXJyb3IoJ0ZhaWxlZCB0byBsb2FkIHNvdXJjZSBtYXAgZm9yJywgZmlsZVVybCwgZXJyb3IpO1xuICAgICAgcmV0dXJuIG51bGw7XG4gICAgfVxuICB9XG5cbiAgcHJpdmF0ZSBub3JtYWxpemVTb3VyY2VQYXRoKHNvdXJjZVBhdGg6IHN0cmluZyk6IHN0cmluZyB7XG4gICAgaWYgKCFzb3VyY2VQYXRoKSByZXR1cm4gc291cmNlUGF0aDtcblxuICAgIC8vIFJlbW92ZSBsZWFkaW5nIFwiLi4vXCIgb3IgXCIuL1wiIHBhdHRlcm5zXG4gICAgbGV0IG5vcm1hbGl6ZWQgPSBzb3VyY2VQYXRoLnJlcGxhY2UoL14oPzpcXC5cXC5cXC8pKy8sICcnKS5yZXBsYWNlKC9eXFwuXFwvLywgJycpO1xuXG4gICAgLy8gUHJlcGVuZCBcImFwcC9cIiBpZiBpdCBzdGFydHMgd2l0aCBcImphdmFzY3JpcHQvXCJcbiAgICBpZiAobm9ybWFsaXplZC5zdGFydHNXaXRoKCdqYXZhc2NyaXB0LycpKSB7XG4gICAgICBub3JtYWxpemVkID0gYGFwcC8ke25vcm1hbGl6ZWR9YDtcbiAgICB9XG5cbiAgICByZXR1cm4gbm9ybWFsaXplZDtcbiAgfVxuXG4gIGFzeW5jIG1hcFN0YWNrVHJhY2Uoc3RhY2s6IHN0cmluZyk6IFByb21pc2U8c3RyaW5nPiB7XG4gICAgaWYgKCFzdGFjaykgcmV0dXJuIHN0YWNrO1xuXG4gICAgY29uc3QgbGluZXMgPSBzdGFjay5zcGxpdCgnXFxuJyk7XG4gICAgY29uc3QgbWFwcGVkTGluZXMgPSBhd2FpdCBQcm9taXNlLmFsbChsaW5lcy5tYXAoYXN5bmMgKGxpbmUpID0+IHtcbiAgICAgIC8vIFBhcnNlIHN0YWNrIHRyYWNlIGxpbmUgLSBoYW5kbGUgbXVsdGlwbGUgZm9ybWF0c1xuICAgICAgLy8gRm9ybWF0IDE6IFwiYXQgZnVuY3Rpb25OYW1lIChodHRwOi8vbG9jYWxob3N0OnBvcnQvYXNzZXRzL2FwcGxpY2F0aW9uLmpzOjEyMzo0NSlcIlxuICAgICAgLy8gRm9ybWF0IDI6IFwiYXQgaHR0cDovL2xvY2FsaG9zdDpwb3J0L2Fzc2V0cy9hcHBsaWNhdGlvbi5qczoxMjM6NDVcIlxuICAgICAgY29uc3QgbWF0Y2ggPSBsaW5lLm1hdGNoKC9eXFxzKmF0XFxzKyg/OiguKz8pXFxzK1xcKCk/KC4rPyk6KFxcZCspOihcXGQrKVxcKT8kLyk7XG4gICAgICBpZiAoIW1hdGNoKSByZXR1cm4gbGluZTtcblxuICAgICAgY29uc3QgWywgZnVuY3Rpb25OYW1lLCBmaWxlVXJsLCBsaW5lU3RyLCBjb2x1bW5TdHJdID0gbWF0Y2g7XG4gICAgICBjb25zdCBsaW5lX251bSA9IHBhcnNlSW50KGxpbmVTdHIsIDEwKTtcbiAgICAgIGNvbnN0IGNvbHVtbiA9IHBhcnNlSW50KGNvbHVtblN0ciwgMTApO1xuXG4gICAgICAvLyBTa2lwIGlmIGZpbGVVcmwgZG9lc24ndCBsb29rIGxpa2UgYSB2YWxpZCBVUkxcbiAgICAgIGlmICghZmlsZVVybCB8fCAoIWZpbGVVcmwuc3RhcnRzV2l0aCgnaHR0cDovLycpICYmICFmaWxlVXJsLnN0YXJ0c1dpdGgoJ2h0dHBzOi8vJykpKSB7XG4gICAgICAgIHJldHVybiBsaW5lO1xuICAgICAgfVxuXG4gICAgICBjb25zdCBjb25zdW1lciA9IGF3YWl0IHRoaXMuZ2V0U291cmNlTWFwQ29uc3VtZXIoZmlsZVVybCk7XG4gICAgICBpZiAoIWNvbnN1bWVyKSByZXR1cm4gbGluZTtcblxuICAgICAgY29uc3Qgb3JpZ2luYWxQb3NpdGlvbiA9IGNvbnN1bWVyLm9yaWdpbmFsUG9zaXRpb25Gb3Ioe1xuICAgICAgICBsaW5lOiBsaW5lX251bSxcbiAgICAgICAgY29sdW1uOiBjb2x1bW5cbiAgICAgIH0pO1xuXG4gICAgICBpZiAob3JpZ2luYWxQb3NpdGlvbi5zb3VyY2UpIHtcbiAgICAgICAgY29uc3Qgbm9ybWFsaXplZFNvdXJjZSA9IHRoaXMubm9ybWFsaXplU291cmNlUGF0aChvcmlnaW5hbFBvc2l0aW9uLnNvdXJjZSk7XG4gICAgICAgIGNvbnN0IHByZWZpeCA9IGZ1bmN0aW9uTmFtZSA/IGBhdCAke2Z1bmN0aW9uTmFtZX0gKGAgOiAnYXQgJztcbiAgICAgICAgY29uc3Qgc3VmZml4ID0gZnVuY3Rpb25OYW1lID8gJyknIDogJyc7XG4gICAgICAgIHJldHVybiBgJHtwcmVmaXh9JHtub3JtYWxpemVkU291cmNlfToke29yaWdpbmFsUG9zaXRpb24ubGluZX06JHtvcmlnaW5hbFBvc2l0aW9uLmNvbHVtbn0ke3N1ZmZpeH1gO1xuICAgICAgfVxuXG4gICAgICByZXR1cm4gbGluZTtcbiAgICB9KSk7XG5cbiAgICByZXR1cm4gbWFwcGVkTGluZXMuam9pbignXFxuJyk7XG4gIH1cblxuICBhc3luYyBlbnJpY2hFcnJvcldpdGhTb3VyY2VNYXAoZXJyb3JJbmZvOiBFcnJvckluZm8pOiBQcm9taXNlPEVycm9ySW5mbz4ge1xuICAgIGxldCBlbnJpY2hlZCA9IHsgLi4uZXJyb3JJbmZvIH07XG5cbiAgICAvLyBNYXAgZmlsZW5hbWUgYW5kIGxpbmUgbnVtYmVyIGlmIGF2YWlsYWJsZVxuICAgIGlmIChlcnJvckluZm8uZmlsZW5hbWUgJiYgZXJyb3JJbmZvLmxpbmVubyAmJiBlcnJvckluZm8uY29sbm8pIHtcbiAgICAgIHRyeSB7XG4gICAgICAgIGNvbnN0IGNvbnN1bWVyID0gYXdhaXQgdGhpcy5nZXRTb3VyY2VNYXBDb25zdW1lcihlcnJvckluZm8uZmlsZW5hbWUpO1xuICAgICAgICBpZiAoY29uc3VtZXIpIHtcbiAgICAgICAgICBjb25zdCBvcmlnaW5hbFBvc2l0aW9uID0gY29uc3VtZXIub3JpZ2luYWxQb3NpdGlvbkZvcih7XG4gICAgICAgICAgICBsaW5lOiBlcnJvckluZm8ubGluZW5vLFxuICAgICAgICAgICAgY29sdW1uOiBlcnJvckluZm8uY29sbm9cbiAgICAgICAgICB9KTtcblxuICAgICAgICAgIGlmIChvcmlnaW5hbFBvc2l0aW9uLnNvdXJjZSkge1xuICAgICAgICAgICAgZW5yaWNoZWQgPSB7XG4gICAgICAgICAgICAgIC4uLmVucmljaGVkLFxuICAgICAgICAgICAgICBmaWxlbmFtZTogdGhpcy5ub3JtYWxpemVTb3VyY2VQYXRoKG9yaWdpbmFsUG9zaXRpb24uc291cmNlKSxcbiAgICAgICAgICAgICAgbGluZW5vOiBvcmlnaW5hbFBvc2l0aW9uLmxpbmUgfHwgZXJyb3JJbmZvLmxpbmVubyxcbiAgICAgICAgICAgICAgY29sbm86IG9yaWdpbmFsUG9zaXRpb24uY29sdW1uICE9PSBudWxsID8gb3JpZ2luYWxQb3NpdGlvbi5jb2x1bW4gOiBlcnJvckluZm8uY29sbm9cbiAgICAgICAgICAgIH07XG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICB9IGNhdGNoIChlcnJvcikge1xuICAgICAgICB0aGlzLm9yaWdpbmFsQ29uc29sZUVycm9yKCdGYWlsZWQgdG8gbWFwIGVycm9yIHBvc2l0aW9uJywgZXJyb3IpO1xuICAgICAgfVxuICAgIH1cblxuICAgIC8vIE1hcCBzdGFjayB0cmFjZSBpZiBhdmFpbGFibGVcbiAgICBpZiAoZXJyb3JJbmZvLmVycm9yPy5zdGFjaykge1xuICAgICAgdHJ5IHtcbiAgICAgICAgY29uc3QgbWFwcGVkU3RhY2sgPSBhd2FpdCB0aGlzLm1hcFN0YWNrVHJhY2UoZXJyb3JJbmZvLmVycm9yLnN0YWNrKTtcbiAgICAgICAgZW5yaWNoZWQgPSB7XG4gICAgICAgICAgLi4uZW5yaWNoZWQsXG4gICAgICAgICAgZXJyb3I6IHtcbiAgICAgICAgICAgIC4uLmVycm9ySW5mby5lcnJvcixcbiAgICAgICAgICAgIHN0YWNrOiBtYXBwZWRTdGFja1xuICAgICAgICAgIH1cbiAgICAgICAgfTtcbiAgICAgIH0gY2F0Y2ggKGVycm9yKSB7XG4gICAgICAgIHRoaXMub3JpZ2luYWxDb25zb2xlRXJyb3IoJ0ZhaWxlZCB0byBtYXAgc3RhY2sgdHJhY2UnLCBlcnJvcik7XG4gICAgICB9XG4gICAgfVxuXG4gICAgcmV0dXJuIGVucmljaGVkO1xuICB9XG59XG5cbi8vIEluaXRpYWxpemUgZXJyb3IgaGFuZGxlciBpbW1lZGlhdGVseSAoZG9uJ3Qgd2FpdCBmb3IgRE9NKVxuLy8gU2luZ2xldG9uIHBhdHRlcm4gdG8gcHJldmVudCBtdWx0aXBsZSBpbnN0YW5jZXNcbmlmICghd2luZG93LmVycm9ySGFuZGxlcikge1xuICB3aW5kb3cuZXJyb3JIYW5kbGVyID0gbmV3IEVycm9ySGFuZGxlcigpO1xufVxuIl0sCiAgIm1hcHBpbmdzIjogIjs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7O0FBQUE7QUFBQTtBQU9BLFFBQUksZUFBZSxtRUFBbUUsTUFBTSxFQUFFO0FBSzlGLFlBQVEsU0FBUyxTQUFV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QU07QUFBQSxjQUMxRCxRQUFRLGlCQUFpQixRQUFRLFVBQVU7QUFBQSxjQUMzQyxPQUFPLGlCQUFpQixXQUFXLE9BQU8saUJBQWlCLFNBQVMsVUFBVTtBQUFBLFlBQ2hGO0FBQUEsVUFDRjtBQUFBLFFBQ0Y7QUFBQSxNQUNGLFNBQVMsT0FBTztBQUNkLGFBQUsscUJBQXFCLGdDQUFnQyxLQUFLO0FBQUEsTUFDakU7QUFBQSxJQUNGO0FBR0EsUUFBSSxVQUFVLE9BQU8sT0FBTztBQUMxQixVQUFJO0FBQ0YsY0FBTSxjQUFjLE1BQU0sS0FBSyxjQUFjLFVBQVUsTUFBTSxLQUFLO0FBQ2xFLG1CQUFXO0FBQUEsVUFDVCxHQUFHO0FBQUEsVUFDSCxPQUFPO0FBQUEsWUFDTCxHQUFHLFVBQVU7QUFBQSxZQUNiLE9BQU87QUFBQSxVQUNUO0FBQUEsUUFDRjtBQUFBLE1BQ0YsU0FBUyxPQUFPO0FBQ2QsYUFBSyxxQkFBcUIsNkJBQTZCLEtBQUs7QUFBQSxNQUM5RDtBQUFBLElBQ0Y7QUFFQSxXQUFPO0FBQUEsRUFDVDtBQUNGO0FBSUEsSUFBSSxDQUFDLE9BQU8sY0FBYztBQUN4QixTQUFPLGVBQWUsSUFBSSxhQUFhO0FBQ3pDOyIsCiAgIm5hbWVzIjogWyJub3JtYWxpemUiLCAic291cmNlRmlsZSIsICJjb21wYXJhdG9yIiwgIlNvdXJjZU1hcENvbnN1bWVyIiwgIm5lZWRsZSIsICJzZWN0aW9uIl0KfQo=
