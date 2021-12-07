import {Component, Input, OnInit} from '@angular/core';
import {Router} from "@angular/router";


@Component({
  selector: 'app-navitem',
  templateUrl: './navitem.component.html',
  styleUrls: ['./navitem.component.scss']
})
export class NavitemComponent implements OnInit {

  @Input()
  /**
   * The name of the page or content this navigation item redirects to.
   */
  name: string | undefined;

  constructor() {
  }

  ngOnInit(): void {
  }

}
