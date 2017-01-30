
describe('header', function() {
  beforeEach(function() {
    MagicLamp.load("layouts/header");
  });

  it ('has the right avatar src', function() {
    expect($("a.dropdown-toggle img").attr("src")).to.equal("https://github.com/foo.png?size=40");
  });
});
