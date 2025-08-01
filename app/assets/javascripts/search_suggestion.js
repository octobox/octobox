SearchSuggestion = {

  init: function() {
    window.indexedDB = window.indexedDB || window.mozIndexedDB || window.webkitIndexedDB || window.msIndexedDB;

    if (!window.indexedDB) {
      return;
    }
    // (Mozilla has never prefixed these objects, so we don't need window.mozIDB*)
    window.IDBTransaction = window.IDBTransaction || window.webkitIDBTransaction || window.msIDBTransaction;
    window.IDBKeyRange = window.IDBKeyRange || window.webkitIDBKeyRange || window.msIDBKeyRange;

    // Let us open our database
    var dbOpenRequest = window.indexedDB.open("SearchSuggestionList", 2);

    dbOpenRequest.onsuccess = function(event) {
      db = dbOpenRequest.result;
    };

    dbOpenRequest.onupgradeneeded = function(event) {
      var db = event.target.result;

      // Create an objectStore for this database
      var objectStore = db.createObjectStore("SearchSuggestionList", { keyPath: "queryString" });
      objectStore.createIndex("timestamp", "timestamp", { unique: false });
    }
  },

  getTimestamp: function() {
    if (!Date.now) {
      Date.now = function() { return new Date().getTime(); }
    }
    return Date.now()
  },

  displaySearchSuggestions: function() {
    if (!db) {
      return;
    }

    var searchQueryList = document.getElementById("search-sugguestion-list");
    searchQueryList.innerHTML = ""
    // Open our object store and then get a cursor list of all the different data items
    // in the IDB to iterate through
    var objectStore = db.transaction(['SearchSuggestionList'], 'readonly').objectStore('SearchSuggestionList');
    var timestampIndex = objectStore.index('timestamp');

    var searchSuggestionFound = false;
    timestampIndex.openCursor(null, 'prev').onsuccess = function(event) {
      var cursor = event.target.result;
      // if there is still another cursor to go, keep running this code
      if (cursor) {
        searchSuggestionFound = true;
        // create a list item to put each data item inside when displaying it
        searchQueryList.appendChild(
          SearchSuggestion.createSuggestionListElement(cursor.value.queryString)
        );                                      // put the item item inside the task list
        cursor.continue();                     // continue on to the next item in the cursor
      }
      if (searchSuggestionFound) {
        searchQueryList.classList.add("d-flex");
      }
    }
  },

  createSuggestionListElement: function(suggestion) {
    var listItem = document.createElement('li');
    listItem.className += 'dropdown-item search-dropdown-item';
    listItem.setAttribute('aria-label', suggestion);

    var divtem = document.createElement('div');
    divtem.setAttribute('aria-label', suggestion);
    divtem.innerHTML = suggestion;

    listItem.appendChild(divtem);
    listItem.innerHTML += SearchSuggestion.createDeleteButtonElement(suggestion);

    return listItem;
  },

  // create a delete button inside each list item, giving it an event handler
  // so that it runs the deleteButton()  when clicked
  createDeleteButtonElement: function(suggestion) {
    return "<div class='badge badge-light search-remove-btn btn' data-suggestion='"+suggestion+"'><svg height='16' class='octicon octicon-x' data-suggestion='"+suggestion+"' viewBox='0 0 12 16' version='1.1' width='12' aria-hidden='true'><path data-suggestion='"+suggestion+"' fill-rule='evenodd' d='M7.48 8l3.75 3.75-1.48 1.48L6 9.48l-3.75 3.75-1.48-1.48L4.52 8 .77 4.25l1.48-1.48L6 6.52l3.75-3.75 1.48 1.48L7.48 8z'></path></svg></div>";
  },

  addToSearchBox: function(event) {
    var queryString = event.target.getAttribute('aria-label');
    document.getElementById("search-box").value = queryString;
    SearchSuggestion.hideSearchSuggestion();
    document.getElementById("search").submit();
  },

  addSearchString: function(searchQuery) {
    if (!db) {
      return;
    }
    if (searchQuery == null || searchQuery == '') {
      return;
    }
    // open a read/write db transaction, ready for adding the data
    var transaction = db.transaction(["SearchSuggestionList"], "readwrite");

    // call an object store that's already been added to the database
    var objectStore = transaction.objectStore("SearchSuggestionList");
    var countRequest = objectStore.count();
    countRequest.onsuccess = function() {
      if (countRequest.result > 10) {
        return;
      }

      var getRequest = objectStore.get(searchQuery);
      getRequest.onsuccess = function(event) {
        if (event.result === searchQuery) {
          return;
        }
        // Make a request to add our newItem object to the object store
        var objectStoreRequest = objectStore.add({queryString: searchQuery, timestamp: SearchSuggestion.getTimestamp()});
      }
    }
  },

  deleteSearchString: function(event) {
    if (!db) {
      return;
    }
    // retrieve the search suggestion we want to delete
    var dataSuggestion = event.target.getAttribute('data-suggestion');

    // open a database transaction and delete the task, finding it by the name we retrieved above
    var transaction = db.transaction(["SearchSuggestionList"], "readwrite");
    var request = transaction.objectStore("SearchSuggestionList").delete(dataSuggestion);

    // report that the data item has been deleted
    transaction.oncomplete = function() {
      SearchSuggestion.displaySearchSuggestions();
    };
  },

  hideSearchSuggestion: function() {
    document.getElementById("search-sugguestion-list").classList.remove('d-flex');
  },

  unblur: function(e) {
    if (!e.target.matches('#search-sugguestion-list')) {
      SearchSuggestion.hideSearchSuggestion();
    }
  }
}
