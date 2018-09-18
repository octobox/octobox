// create an instance of a db object for us to store the IDB data in
var db;
var searchQueryList = document.getElementById("search-sugguestion-list");
var maxLimit = 10;

if (!Date.now) {
  Date.now = function() { return new Date().getTime(); }
}

window.onload = function() {

  window.indexedDB = window.indexedDB || window.mozIndexedDB || window.webkitIndexedDB || window.msIndexedDB;

  if (!window.indexedDB) {
    return;
  }

  // (Mozilla has never prefixed these objects, so we don't need window.mozIDB*)
  window.IDBTransaction = window.IDBTransaction || window.webkitIDBTransaction || window.msIDBTransaction;
  window.IDBKeyRange = window.IDBKeyRange || window.webkitIDBKeyRange || window.msIDBKeyRange;

  // Let us open our database
  var DBOpenRequest = window.indexedDB.open("SearchSuggestionList", 2);

  // these two event handlers act on the database being opened successfully, or not
  DBOpenRequest.onerror = function(event) {
    console.log("Error loading database.");
  };

  DBOpenRequest.onsuccess = function(event) {
    db = DBOpenRequest.result;
  };

  DBOpenRequest.onupgradeneeded = function(event) {
    var db = event.target.result;

    db.onerror = function(event) {
      console.log('Error loading database');
    };

    // Create an objectStore for this database
    var objectStore = db.createObjectStore("SearchSuggestionList", { keyPath: "queryString" });
    objectStore.createIndex("timestamp", "timestamp", { unique: false });
    console.log("Object store created.");
  }
}

function displaySearchSuggestions() {
  if (!window.indexedDB || !db) {
    return;
  }
  searchQueryList.innerHTML = ""
  var ulItem = document.createElement('ul');
  // Open our object store and then get a cursor list of all the different data items
  // in the IDB to iterate through
  var objectStore = db.transaction(['SearchSuggestionList'], 'readonly').objectStore('SearchSuggestionList');
  var timestampIndex = objectStore.index('timestamp');

  timestampIndex.openCursor(null, 'prev').onsuccess = function(event) {
    var cursor = event.target.result;
    // if there is still another cursor to go, keep runing this code
    if(cursor) {
      // create a list item to put each data item inside when displaying it
      searchQueryList.appendChild(
        createSuggestionListElement(cursor.value.queryString)
      );                                      // put the item item inside the task list
      searchQueryList.appendChild(
        createDividerElement()
      );
      cursor.continue();                     // continue on to the next item in the cursor
    }
  }
  searchQueryList.classList.add("d-block");
}

function createDividerElement() {
  var dividerItem = document.createElement('div');
  dividerItem.className += 'dropdown-divider search-divider-item';
  return dividerItem;
}

function createSuggestionListElement(suggestion) {
  var listItem = document.createElement('li');
  listItem.className += 'dropdown-item search-dropdown-item';
  listItem.setAttribute('aria-selected', 'false');
  listItem.setAttribute('aria-label', suggestion);
  listItem.innerHTML = suggestion;
  return listItem;
}

// create a delete button inside each list item, giving it an event handler
// so that it runs the deleteButton() function when clicked
function createDeleteButtonElement(suggestion) {
  var deleteButton = document.createElement('button');
  deleteButton.innerHTML = 'X';
  deleteButton.setAttribute('data-suggestion', suggestion);

  deleteButton.onclick = function(event) {
    deleteQueryString(event);
  }

  return deleteButton;
}

function isMaxLimitReached(objectStore) {
  var countRequest = objectStore.count();
  countRequest.onsuccess = function() {
    if (countRequest.result >= maxLimit);
    return true;
  }

  return false;
}

function isPresentSearchQuery(objectStore, searchQuery) {
  var getRequest = objectStore.get(searchQuery)
  getRequest.onsuccess = function(event) {
    if (event.target.result === searchQuery) {
      return true;
    }
  }

  return false;
}

function addQueryString(searchQuery) {
  if (!window.indexedDB) {
    return;
  }

  if (searchQuery == null || searchQuery == '') {
    return;
  }

  // open a read/write db transaction, ready for adding the data
  var transaction = db.transaction(["SearchSuggestionList"], "readwrite");
  transaction.onerror = function() {
    console.log('Transaction not opened due to error: ' + transaction.error);
  };

  // call an object store that's already been added to the database
  var objectStore = transaction.objectStore("SearchSuggestionList");

  if (isMaxLimitReached(objectStore)) {
    console.log("Max Limit Reached for Storing Query String");
    return;
  }

  // Make a request to add our newItem object to the object store
  var objectStoreRequest = objectStore.add({queryString: searchQuery, timestamp: Date.now()});
  objectStoreRequest.onsuccess = function(event) {
    console.log('Search Suggestion to Added IndexedDB :: ' + searchQuery);
  };
};

function deleteQueryString(event) {
  if (!window.indexedDB) {
    return;
  }
  // retrieve the search suggestion we want to delete
  var dataSuggestion = event.target.getAttribute('data-suggestion');

  // open a database transaction and delete the task, finding it by the name we retrieved above
  var transaction = db.transaction(["SearchSuggestionList"], "readwrite");
  var request = transaction.objectStore("SearchSuggestionList").delete(dataSuggestion);

  // report that the data item has been deleted
  transaction.oncomplete = function() {
    console.log('Search Suggestion deleted.')
  };
};
