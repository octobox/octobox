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
  var dbOpenRequest = window.indexedDB.open("SearchSuggestionList", 2);

  // these two event handlers act on the database being opened successfully, or not
  dbOpenRequest.onerror = function(event) {
    console.log("Error loading database.");
  };

  dbOpenRequest.onsuccess = function(event) {
    db = dbOpenRequest.result;
  };

  dbOpenRequest.onupgradeneeded = function(event) {
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
  listItem.setAttribute('aria-label', suggestion);

  var divtem = document.createElement('div');
  divtem.setAttribute('aria-label', suggestion);
  divtem.innerHTML = suggestion;

  listItem.appendChild(divtem);
  listItem.appendChild(createDeleteButtonElement(suggestion));

  return listItem;
}

function addQueryToSearchBox(event) {
  var queryString = event.target.getAttribute('aria-label');
  if(queryString) {
    if ($("#search-box").val().length > 0) {
      var search_value = $("#search-box").val() + "," + queryString;
      $("#search-box").val(search_value);
    }
    else {
     $("#search-box").val(queryString);
    }
  }

  $("#search-sugguestion-list").removeClass('d-block');
}

// create a delete button inside each list item, giving it an event handler
// so that it runs the deleteButton() function when clicked
function createDeleteButtonElement(suggestion) {
  var deleteButton = document.createElement('button');
  deleteButton.className += 'search-remove-btn btn btn-link'
  deleteButton.innerHTML = 'X';
  deleteButton.setAttribute('data-suggestion', suggestion);

  deleteButton.onclick = function(event) {
    deleteQueryString(event);
  }

  return deleteButton;
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
  var countRequest = objectStore.count();
  countRequest.onsuccess = function() {
    if (countRequest.result > maxLimit) {
      return;
    }

    var getRequest = objectStore.get(searchQuery);
    getRequest.onsuccess = function(event) {
      if (event.result === searchQuery) {
        return;
      }
      // Make a request to add our newItem object to the object store
      var objectStoreRequest = objectStore.add({queryString: searchQuery, timestamp: Date.now()});
      objectStoreRequest.onsuccess = function(event) {
        console.log('Search Suggestion to Added IndexedDB :: ' + searchQuery);
      };
    }
  }
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
    displaySearchSuggestions();
    console.log('Search Suggestion deleted.')
  };
};

function hideSearchSuggestion() {
  $(document).mouseup(function(e) {
    var container = $("#search-sugguestion-list");
    if (!container.is(e.target) && container.has(e.target).length === 0) {
      container.removeClass('d-block');
    }
  });
}
