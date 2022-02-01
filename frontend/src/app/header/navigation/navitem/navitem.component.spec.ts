import { ComponentFixture, TestBed } from '@angular/core/testing';

import { NavitemComponent } from './navitem.component';

describe('NavitemComponent', () => {
  let component: NavitemComponent;
  let fixture: ComponentFixture<NavitemComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ NavitemComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(NavitemComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
