// create an instance of a db object for us to store the IDB data in
var db;
var searchQueryList = document.getElementById("search-sugguestion-list");

(function() {

  window.indexedDB = window.indexedDB || window.mozIndexedDB || window.webkitIndexedDB || window.msIndexedDB;
  // (Mozilla has never prefixed these objects, so we don't need window.mozIDB*)
  window.IDBTransaction = window.IDBTransaction || window.webkitIDBTransaction || window.msIDBTransaction;
  window.IDBKeyRange = window.IDBKeyRange || window.webkitIDBKeyRange || window.msIDBKeyRange;


  if (!window.indexedDB) {
    return;
  }
  // Let us open our database
  var DBOpenRequest = window.indexedDB.open("SearchSuggestionList", 1);

  // these two event handlers act on the database being opened successfully, or not
  DBOpenRequest.onerror = function(event) {
    console.log("Error loading database.");
  };

  DBOpenRequest.onsuccess = function(event) {
    db = DBOpenRequest.result;
  };
}

function displaySearchSuggestions() {
  searchQueryList.innerHTML = "";
  // Open our object store and then get a cursor list of all the different data items
  // in the IDB to iterate through
  var objectStore = db.transaction('SearchSuggestionList').objectStore('SearchSuggestionList');
  var queryIndex = objectStore.index('queryString');

  queryIndex.openCursor().onsuccess = function(event) {
    var cursor = event.target.result;
    // if there is still another cursor to go, keep runing this code
    if(cursor) {
      // create a list item to put each data item inside when displaying it
      createSuggestionListElement(cursor.value.queryString);
      searchQueryList.appendChild(listItem); // put the item item inside the task list
      cursor.continue();                     // continue on to the next item in the cursor
    }
  }
}

function createSuggestionListElement(suggestion) {
  var listItem = document.createElement('li');
  listItem.className += ' d-flex flex-justify-start flex-items-center p-0 f5 navigation-item js-navigation-item';
  listItem.setAttribute('aria-selected', 'false');
  listItem.setAttribute('id', 'jump-to-suggestion');

  var divItem = document.createElement('div');
  divItem.className += ' js-jump-to-suggestion-name overflow-hidden text-left no-wrap css-truncate css-truncate-target';
  divItem.setAttribute('aria-label', suggestion);
  divItem.innerHTML = suggestion;

  listItem.appendChild(divItem);
  listItem.appendChild(createDeleteButtonElement(suggestion));

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

function addQueryString(searchQuery) {
  // open a read/write db transaction, ready for adding the data
  var transaction = db.transaction(["SearchSuggestionList"], "readwrite");
  transaction.onerror = function() {
    console.log('Transaction not opened due to error: ' + transaction.error);
  };

  // call an object store that's already been added to the database
  var objectStore = transaction.objectStore("SearchSuggestionList");

  // Make a request to add our newItem object to the object store
  var objectStoreRequest = objectStore.add({queryString: searchQuery});
  objectStoreRequest.onsuccess = function(event) {
    console.log('Add Search Suggestion to IndexedDB');
  };
};

function deleteQueryString(event) {
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
