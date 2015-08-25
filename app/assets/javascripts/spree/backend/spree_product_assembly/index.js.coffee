#= require ./translations

$(document).ready ->
  Spree.routes.available_admin_product_parts = (productSlug) ->
    Spree.pathFor("admin/products/" + productSlug + "/parts/available")

  showErrorMessages = (xhr) ->
    response = JSON.parse(xhr.responseText)
    show_flash("error", response)

  partsTable = $("#product_parts")
  searchResults = $("#search_hits")

  searchForParts = ->
    productSlug = partsTable.data("product-slug")
    searchUrl = Spree.routes.available_admin_product_parts(productSlug)

    $.ajax
     data:
       q: $("#searchtext").val()
     dataType: 'html'
     success: (request) ->
       searchResults.html(request)
       searchResults.show()
     type: 'POST'
     url: searchUrl

  $("#searchtext").keypress (e) ->
    if (e.which && e.which == 13) || (e.keyCode && e.keyCode == 13)
      searchForParts()
      false
    else
      true

  $("#search_parts_button").click (e) ->
    e.preventDefault()
    searchForParts()

  makePostRequest = (link, post_params = {}) ->
    spinner = $("img.spinner", link.parent())
    spinner.show()

    request = $.ajax
      type: "POST"
      url: link.attr("href")
      data: post_params
      dateType: "script"
    request.fail showErrorMessages
    request.always -> spinner.hide()

    false

  searchResults.on "click", "a.add_product_part_link", (event) ->
    event.preventDefault()

    part = {}
    link = $(this)
    row = $("#" + link.data("target"))
    loadingIndicator = $("img.spinner", link.parent())
    quantityField = $('input:last', row)

    part.count = quantityField.val()

    if row.hasClass("with-variants")
      selectedVariantOption = $('select option:selected', row)
      part.variant_id = selectedVariantOption.val()

      if selectedVariantOption.text() == Spree.translations.user_selectable
        part.variant_selection_deferred = "t"
        part.variant_id = link.data("master-variant-id")

    else
      part.variant_id = $('input[name="part[id]"]', row).val()

    makePostRequest(link, {assemblies_part: part})

  partsTable.on "click", "a.set_count_admin_product_part_link", ->
    params = { count: $("input", $(this).parent().parent()).val() }
    makePostRequest($(this), params)

  partsTable.on "click", "a.remove_admin_product_part_link", ->
    makePostRequest($(this))
