  var TEST_INTERFACE_COUNT = 5;

  function arrayFromNodeList(nodeList) {
    return Array.prototype.slice.call(nodeList);
  }

  function requestIndexDocument(callback) {
    console.log('Requesting index...');

    var request = new XMLHttpRequest();
    request.responseType = 'document';
    request.open('GET', 'https://developer.mozilla.org/en-US/docs/Web/API');
    request.onreadystatechange = function() {
      if (request.readyState != XMLHttpRequest.DONE) {
        return;
      }

      callback(request.response);
    };
    request.send();
  }

  function parseInterfaceNamesFromIndex(indexDocument) {
    console.log('Parsing interface names and URLs...');
    var interfacesNodeList = indexDocument.querySelectorAll('.indexListRow code a');
    var interfaceNodes = arrayFromNodeList(interfacesNodeList);
    var interfaces = interfaceNodes.map(function(node) {
      return {
        name: node.innerHTML,
        mdn_url: node.href
      };
    });

    return interfaces;
  }

  function completeInterfaceDataWithDocument(anInterface, interfaceDocument) {
    console.log('Completing data for ' + anInterface + ' with document:', interfaceDocument);
  }

  function completeInterfaceData(anInterface) {
    console.log('Requesting interface page for', anInterface.name);
    var request = new XMLHttpRequest();
    request.open('GET', anInterface.mdn_url);
    request.responseType = 'document';
    request.onreadystatechange = function() {
      if (request.readyState != XMLHttpRequest.DONE) {
        return;
      }

      completeInterfaceDataWithDocument(anInterface, request.response);
    };
    request.send();
  }

  requestIndexDocument(function(indexDocument) {
    var interfaces = parseInterfaceNamesFromIndex(indexDocument);
    console.log('Parsed interfaces: ', interfaces);

    console.log('Requesting individual interface pages...');
    interfaces.slice(0, TEST_INTERFACE_COUNT).forEach(function(thisInterface) {
      completeInterfaceData(thisInterface);
    });
  });