import { queryAll } from "discourse/tests/helpers/qunit-helpers";
import { exists } from "discourse/tests/helpers/qunit-helpers";
import { click, fillIn, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("Composer topic featured links", function (needs) {
  needs.user();
  needs.settings({
    topic_featured_link_enabled: true,
    max_topic_title_length: 80,
    enable_markdown_linkify: true,
  });

  test("onebox with title", async (assert) => {
    await visit("/");
    await click("#create-topic");
    await fillIn("#reply-title", "http://www.example.com/has-title.html");
    assert.ok(
      queryAll(".d-editor-preview").html().trim().indexOf("onebox") > 0,
      "it pastes the link into the body and previews it"
    );
    assert.ok(
      exists(".d-editor-textarea-wrapper .popup-tip.good"),
      "the body is now good"
    );
    assert.equal(
      queryAll(".title-input input").val(),
      "An interesting article",
      "title is from the oneboxed article"
    );
  });

  test("onebox result doesn't include a title", async (assert) => {
    await visit("/");
    await click("#create-topic");
    await fillIn("#reply-title", "http://www.example.com/no-title.html");
    assert.ok(
      queryAll(".d-editor-preview").html().trim().indexOf("onebox") > 0,
      "it pastes the link into the body and previews it"
    );
    assert.ok(
      exists(".d-editor-textarea-wrapper .popup-tip.good"),
      "the body is now good"
    );
    assert.equal(
      queryAll(".title-input input").val(),
      "http://www.example.com/no-title.html",
      "title is unchanged"
    );
  });

  test("no onebox result", async (assert) => {
    await visit("/");
    await click("#create-topic");
    await fillIn("#reply-title", "http://www.example.com/nope-onebox.html");
    assert.ok(
      queryAll(".d-editor-preview").html().trim().indexOf("onebox") > 0,
      "it pastes the link into the body and previews it"
    );
    assert.ok(
      exists(".d-editor-textarea-wrapper .popup-tip.good"),
      "link is pasted into body"
    );
    assert.equal(
      queryAll(".title-input input").val(),
      "http://www.example.com/nope-onebox.html",
      "title is unchanged"
    );
  });

  test("ignore internal links", async (assert) => {
    await visit("/");
    await click("#create-topic");
    const title = "http://" + window.location.hostname + "/internal-page.html";
    await fillIn("#reply-title", title);
    assert.equal(
      queryAll(".d-editor-preview").html().trim().indexOf("onebox"),
      -1,
      "onebox preview doesn't show"
    );
    assert.equal(
      queryAll(".d-editor-input").val().length,
      0,
      "link isn't put into the post"
    );
    assert.equal(
      queryAll(".title-input input").val(),
      title,
      "title is unchanged"
    );
  });

  test("link is longer than max title length", async (assert) => {
    await visit("/");
    await click("#create-topic");
    await fillIn(
      "#reply-title",
      "http://www.example.com/has-title-and-a-url-that-is-more-than-80-characters-because-thats-good-for-seo-i-guess.html"
    );
    assert.ok(
      queryAll(".d-editor-preview").html().trim().indexOf("onebox") > 0,
      "it pastes the link into the body and previews it"
    );
    assert.ok(
      exists(".d-editor-textarea-wrapper .popup-tip.good"),
      "the body is now good"
    );
    assert.equal(
      queryAll(".title-input input").val(),
      "An interesting article",
      "title is from the oneboxed article"
    );
  });

  test("onebox with title but extra words in title field", async (assert) => {
    await visit("/");
    await click("#create-topic");
    await fillIn("#reply-title", "http://www.example.com/has-title.html test");
    assert.equal(
      queryAll(".d-editor-preview").html().trim().indexOf("onebox"),
      -1,
      "onebox preview doesn't show"
    );
    assert.equal(
      queryAll(".d-editor-input").val().length,
      0,
      "link isn't put into the post"
    );
    assert.equal(
      queryAll(".title-input input").val(),
      "http://www.example.com/has-title.html test",
      "title is unchanged"
    );
  });
});

acceptance(
  "Composer topic featured links when uncategorized is not allowed",
  function (needs) {
    needs.user({ moderator: true, admin: false, trust_level: 1 });
    needs.settings({
      topic_featured_link_enabled: true,
      max_topic_title_length: 80,
      enable_markdown_linkify: true,
      allow_uncategorized_topics: false,
    });

    test("Pasting a link enables the text input area", async (assert) => {
      await visit("/");
      await click("#create-topic");
      assert.ok(
        queryAll(".d-editor-textarea-wrapper.disabled").length,
        "textarea is disabled"
      );
      await fillIn("#reply-title", "http://www.example.com/has-title.html");
      assert.ok(
        queryAll(".d-editor-preview").html().trim().indexOf("onebox") > 0,
        "it pastes the link into the body and previews it"
      );
      assert.ok(
        exists(".d-editor-textarea-wrapper .popup-tip.good"),
        "the body is now good"
      );
      assert.equal(
        queryAll(".title-input input").val(),
        "An interesting article",
        "title is from the oneboxed article"
      );
      assert.ok(
        queryAll(".d-editor-textarea-wrapper.disabled").length === 0,
        "textarea is enabled"
      );
    });
  }
);
